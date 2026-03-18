import { Injectable, Logger, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { JwtPayload, RedisService } from '@interaedu/shared';
import { PostEntity } from '../database/entities/post.entity';
import { ReactionEntity, ReactionType } from '../database/entities/reaction.entity';
import { CommentEntity } from '../database/entities/comment.entity';
import { CreatePostDto } from './dto/create-post.dto';

@Injectable()
export class PostsService {
  private readonly logger = new Logger(PostsService.name);

  constructor(
    @InjectRepository(PostEntity)
    private readonly postRepo: Repository<PostEntity>,
    @InjectRepository(ReactionEntity)
    private readonly reactionRepo: Repository<ReactionEntity>,
    @InjectRepository(CommentEntity)
    private readonly commentRepo: Repository<CommentEntity>,
    private readonly redis: RedisService,
  ) {}

  async getFeed(scope: string, cursor: string, limit: number, user: JwtPayload) {
    const normalizedScope = scope === 'global' ? 'global' : 'local';
    const take = Math.min(Math.max(limit || 20, 1), 50);
    const cursorDate = this.decodeCursor(cursor);

    const cacheKey = `feed:${normalizedScope}:${user.institution_id}:${cursorDate?.toISOString() ?? 'first'}:${take}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const response =
      normalizedScope === 'local'
        ? await this.getLocalFeed(user, cursorDate, take)
        : await this.getGlobalFeed(user, cursorDate, take);

    await this.redis.set(cacheKey, JSON.stringify(response), 60);
    return response;
  }

  async create(dto: CreatePostDto, user: JwtPayload) {
    const post = await this.postRepo.save({
      authorId: user.sub,
      institutionId: user.institution_id,
      content: dto.content,
      scope: dto.scope ?? 'global',
      mediaUrls: dto.media_urls ?? null,
    });

    // Best-effort cache invalidation
    await this.invalidateFeedCaches(user.institution_id);

    return { id: post.id };
  }

  async findById(id: string) {
    const post = await this.postRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!post) throw new NotFoundException('Post not found');
    return this.toPostResponse(post, undefined);
  }

  async softDelete(id: string, userId: string) {
    const post = await this.postRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== userId) throw new ForbiddenException('Not allowed');

    post.deletedAt = new Date();
    await this.postRepo.save(post);
    await this.invalidateFeedCaches(post.institutionId);
  }

  async addReaction(postId: string, type: string, userId: string) {
    const reactionType = type as ReactionType;
    if (!['like', 'insightful', 'support'].includes(reactionType)) {
      throw new ForbiddenException('Invalid reaction type');
    }

    const post = await this.postRepo.findOne({ where: { id: postId, deletedAt: IsNull() } });
    if (!post) throw new NotFoundException('Post not found');

    const existing = await this.reactionRepo.findOne({ where: { postId, userId } });
    if (existing) throw new ConflictException('Already reacted');

    await this.reactionRepo.save({ postId, userId, reactionType });
    post.reactionCount += 1;
    await this.postRepo.save(post);

    await this.invalidateFeedCaches(post.institutionId);
    return { message: 'Reaction added' };
  }

  async getComments(postId: string, cursor: string) {
    const take = 50;
    const cursorDate = this.decodeCursor(cursor);

    const qb = this.commentRepo
      .createQueryBuilder('c')
      .where('c.post_id = :postId', { postId })
      .andWhere('c.deleted_at IS NULL')
      .orderBy('c.created_at', 'DESC')
      .take(take + 1);

    if (cursorDate) qb.andWhere('c.created_at < :cursor', { cursor: cursorDate.toISOString() });

    const rows = await qb.getMany();
    const hasMore = rows.length > take;
    const page = rows.slice(0, take);

    return {
      data: page.map((c) => ({
        id: c.id,
        post_id: c.postId,
        user_id: c.userId,
        parent_comment_id: c.parentCommentId ?? null,
        content: c.content,
        created_at: c.createdAt.toISOString(),
      })),
      pagination: {
        cursor: hasMore ? this.encodeCursor(page[page.length - 1]?.createdAt) : null,
        has_more: hasMore,
      },
    };
  }

  async addComment(postId: string, dto: any, userId: string) {
    const post = await this.postRepo.findOne({ where: { id: postId, deletedAt: IsNull() } });
    if (!post) throw new NotFoundException('Post not found');

    const content = typeof dto?.content === 'string' ? dto.content.trim() : '';
    if (!content) throw new ForbiddenException('Content is required');

    const comment = await this.commentRepo.save({
      postId,
      userId,
      parentCommentId: dto?.parent_comment_id ?? null,
      content,
    });

    post.commentCount += 1;
    await this.postRepo.save(post);

    await this.invalidateFeedCaches(post.institutionId);
    return { id: comment.id };
  }

  private async getLocalFeed(user: JwtPayload, cursorDate: Date | null, limit: number) {
    const qb = this.postRepo
      .createQueryBuilder('p')
      .where('p.deleted_at IS NULL')
      .andWhere('p.institution_id = :inst', { inst: user.institution_id })
      .orderBy('p.created_at', 'DESC')
      .take(limit + 1);

    if (cursorDate) qb.andWhere('p.created_at < :cursor', { cursor: cursorDate.toISOString() });

    const rows = await qb.getMany();
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    // Edge case: if institution has too little content, fill with global posts from other institutions
    let finalPage = page;
    if (!cursorDate && page.length < 5) {
      const fill = await this.postRepo
        .createQueryBuilder('p')
        .where('p.deleted_at IS NULL')
        .andWhere('p.scope = :scope', { scope: 'global' })
        .andWhere('p.institution_id <> :inst', { inst: user.institution_id })
        .orderBy('p.created_at', 'DESC')
        .take(5 - page.length)
        .getMany();
      finalPage = [...page, ...fill];
    }

    return {
      data: finalPage.map((p) => this.toPostResponse(p, user.sub)),
      pagination: {
        cursor: hasMore ? this.encodeCursor(page[page.length - 1]?.createdAt) : null,
        has_more: hasMore,
      },
    };
  }

  private async getGlobalFeed(user: JwtPayload, cursorDate: Date | null, limit: number) {
    const externalCount = Math.max(1, Math.ceil(limit * 0.2));
    const localCount = Math.max(0, limit - externalCount);

    const localQb = this.postRepo
      .createQueryBuilder('p')
      .where('p.deleted_at IS NULL')
      .andWhere('p.scope = :scope', { scope: 'global' })
      .andWhere('p.institution_id = :inst', { inst: user.institution_id })
      .orderBy('p.created_at', 'DESC')
      .take(localCount);

    const externalQb = this.postRepo
      .createQueryBuilder('p')
      .where('p.deleted_at IS NULL')
      .andWhere('p.scope = :scope', { scope: 'global' })
      .andWhere('p.institution_id <> :inst', { inst: user.institution_id })
      .orderBy('p.created_at', 'DESC')
      .take(externalCount);

    if (cursorDate) {
      localQb.andWhere('p.created_at < :cursor', { cursor: cursorDate.toISOString() });
      externalQb.andWhere('p.created_at < :cursor', { cursor: cursorDate.toISOString() });
    }

    const [local, external] = await Promise.all([localQb.getMany(), externalQb.getMany()]);
    const merged = [...local, ...external].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    const page = merged.slice(0, limit);
    return {
      data: page.map((p) => this.toPostResponse(p, user.sub)),
      pagination: {
        cursor: page.length ? this.encodeCursor(page[page.length - 1].createdAt) : null,
        has_more: merged.length > limit,
      },
    };
  }

  private toPostResponse(p: PostEntity, viewerId?: string) {
    return {
      id: p.id,
      author: { id: p.authorId, institution_id: p.institutionId },
      content: p.content,
      scope: p.scope,
      media_urls: p.mediaUrls ?? [],
      reaction_count: p.reactionCount,
      comment_count: p.commentCount,
      user_reaction: null,
      created_at: p.createdAt.toISOString(),
      viewer_id: viewerId ?? null,
    };
  }

  private encodeCursor(date?: Date) {
    if (!date) return null;
    return Buffer.from(JSON.stringify({ t: date.toISOString() })).toString('base64');
  }

  private decodeCursor(cursor?: string): Date | null {
    if (!cursor) return null;
    try {
      const raw = Buffer.from(cursor, 'base64').toString('utf8');
      const parsed = JSON.parse(raw);
      const d = new Date(parsed.t);
      return isNaN(d.getTime()) ? null : d;
    } catch {
      return null;
    }
  }

  private async invalidateFeedCaches(institutionId: string) {
    // MVP: we don't scan keys (expensive). Cache TTL is short, so log and rely on TTL.
    this.logger.debug(`Feed cache invalidation requested for institution ${institutionId}`);
  }
}
