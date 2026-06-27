import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull } from 'typeorm';
import { JwtPayload } from '@interaedu/shared';
import { TagEntity } from '../database/entities/tag.entity';
import { PostTagEntity } from '../database/entities/post-tag.entity';
import { TagFollowEntity } from '../database/entities/tag-follow.entity';
import { PostEntity } from '../database/entities/post.entity';

const PROFILE_SERVICE_URL = process.env.PROFILE_SERVICE_URL ?? 'http://profile-service:3002';

@Injectable()
export class TagsService {
  constructor(
    @InjectRepository(TagEntity)
    private readonly tagRepo: Repository<TagEntity>,
    @InjectRepository(PostTagEntity)
    private readonly postTagRepo: Repository<PostTagEntity>,
    @InjectRepository(TagFollowEntity)
    private readonly followRepo: Repository<TagFollowEntity>,
    @InjectRepository(PostEntity)
    private readonly postRepo: Repository<PostEntity>,
  ) {}

  /// Reads or creates tags by slug. Returns map slug -> TagEntity.
  async upsertMany(slugs: string[]): Promise<Map<string, TagEntity>> {
    if (!slugs.length) return new Map();
    const existing = await this.tagRepo.find({ where: { slug: In(slugs) } });
    const map = new Map(existing.map((t) => [t.slug, t]));
    const missing = slugs.filter((s) => !map.has(s));
    for (const slug of missing) {
      const t = await this.tagRepo.save({ slug, name: slug });
      map.set(slug, t);
    }
    return map;
  }

  async attachToPost(postId: string, slugs: string[]) {
    if (!slugs.length) return;
    const tags = await this.upsertMany(slugs);
    for (const tag of tags.values()) {
      const existing = await this.postTagRepo.findOne({
        where: { postId, tagId: tag.id },
      });
      if (!existing) {
        await this.postTagRepo.save({ postId, tagId: tag.id });
        await this.tagRepo.increment({ id: tag.id }, 'postCount', 1);
      }
    }
  }

  async search(q?: string) {
    const qb = this.tagRepo
      .createQueryBuilder('t')
      .orderBy('t.post_count', 'DESC')
      .take(20);
    if (q && q.trim()) qb.andWhere('t.slug ILIKE :q', { q: `${q.trim().toLowerCase()}%` });
    const items = await qb.getMany();
    return { data: items.map((t) => this.toResponse(t)) };
  }

  async trending(user: JwtPayload) {
    const items = await this.tagRepo.find({
      order: { postCount: 'DESC' },
      take: 10,
    });
    const myFollows = await this.followRepo.find({
      where: { userId: user.sub, tagId: In(items.map((t) => t.id)) },
    });
    const set = new Set(myFollows.map((f) => f.tagId));
    return { data: items.map((t) => this.toResponse(t, set.has(t.id))) };
  }

  async getBySlug(slug: string, user: JwtPayload) {
    const t = await this.tagRepo.findOne({ where: { slug: slug.toLowerCase() } });
    if (!t) throw new NotFoundException('Tag não encontrada');
    const f = await this.followRepo.findOne({ where: { tagId: t.id, userId: user.sub } });
    return this.toResponse(t, !!f);
  }

  async postsByTag(slug: string, cursor: string | undefined, user: JwtPayload, authToken: string) {
    const t = await this.tagRepo.findOne({ where: { slug: slug.toLowerCase() } });
    if (!t) throw new NotFoundException('Tag não encontrada');
    const links = await this.postTagRepo.find({
      where: { tagId: t.id },
      order: { createdAt: 'DESC' },
      take: 50,
    });
    if (!links.length) return { data: [] };

    const posts = await this.postRepo.find({
      where: { id: In(links.map((l) => l.postId)), deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });

    const authorIds = [...new Set(posts.map((p) => p.authorId))];
    const profileMap = new Map<string, any>();
    try {
      const resp = await fetch(`${PROFILE_SERVICE_URL}/users/batch?ids=${authorIds.join(',')}`, {
        headers: { Authorization: authToken },
      });
      if (resp.ok) {
        const body = (await resp.json()) as { data: any[] };
        (body?.data ?? []).forEach((p) => profileMap.set(p.id, p));
      }
    } catch {}

    return {
      data: posts.map((p) => ({
        id: p.id,
        content: p.content,
        media_urls: p.mediaUrls ?? [],
        reaction_count: p.reactionCount,
        comment_count: p.commentCount,
        created_at: p.createdAt.toISOString(),
        author: {
          id: p.authorId,
          full_name: profileMap.get(p.authorId)?.full_name ?? null,
          avatar_url: profileMap.get(p.authorId)?.avatar_url ?? null,
        },
      })),
    };
  }

  async follow(slug: string, user: JwtPayload) {
    const t = await this.tagRepo.findOne({ where: { slug: slug.toLowerCase() } });
    if (!t) throw new NotFoundException('Tag não encontrada');
    const existing = await this.followRepo.findOne({
      where: { tagId: t.id, userId: user.sub },
    });
    if (existing) return { message: 'OK' };
    await this.followRepo.save({ tagId: t.id, userId: user.sub });
    await this.tagRepo.increment({ id: t.id }, 'followerCount', 1);
    return { message: 'OK' };
  }

  async unfollow(slug: string, user: JwtPayload) {
    const t = await this.tagRepo.findOne({ where: { slug: slug.toLowerCase() } });
    if (!t) throw new NotFoundException('Tag não encontrada');
    const existing = await this.followRepo.findOne({
      where: { tagId: t.id, userId: user.sub },
    });
    if (!existing) return { message: 'OK' };
    await this.followRepo.remove(existing);
    await this.tagRepo.decrement({ id: t.id }, 'followerCount', 1);
    return { message: 'OK' };
  }

  async myFollowed(user: JwtPayload) {
    const follows = await this.followRepo.find({
      where: { userId: user.sub },
      order: { createdAt: 'DESC' },
    });
    if (!follows.length) return { data: [] };
    const tags = await this.tagRepo.find({
      where: { id: In(follows.map((f) => f.tagId)) },
    });
    return { data: tags.map((t) => this.toResponse(t, true)) };
  }

  private toResponse(t: TagEntity, isFollowed = false) {
    return {
      id: t.id,
      slug: t.slug,
      name: t.name,
      post_count: t.postCount,
      follower_count: t.followerCount,
      is_followed: isFollowed,
    };
  }
}
