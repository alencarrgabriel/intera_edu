import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull } from 'typeorm';
import { JwtPayload } from '@interaedu/shared';
import { BookmarkEntity } from '../database/entities/bookmark.entity';
import { PostEntity } from '../database/entities/post.entity';

const PROFILE_SERVICE_URL = process.env.PROFILE_SERVICE_URL ?? 'http://profile-service:3002';

@Injectable()
export class BookmarksService {
  constructor(
    @InjectRepository(BookmarkEntity)
    private readonly bookmarkRepo: Repository<BookmarkEntity>,
    @InjectRepository(PostEntity)
    private readonly postRepo: Repository<PostEntity>,
  ) {}

  async add(postId: string, user: JwtPayload) {
    const post = await this.postRepo.findOne({ where: { id: postId, deletedAt: IsNull() } });
    if (!post) throw new NotFoundException('Post não encontrado');
    const existing = await this.bookmarkRepo.findOne({
      where: { postId, userId: user.sub },
    });
    if (existing) return { message: 'OK' };
    await this.bookmarkRepo.save({ postId, userId: user.sub });
    return { message: 'OK' };
  }

  async remove(postId: string, user: JwtPayload) {
    const existing = await this.bookmarkRepo.findOne({
      where: { postId, userId: user.sub },
    });
    if (existing) await this.bookmarkRepo.remove(existing);
    return { message: 'OK' };
  }

  async list(user: JwtPayload, authToken: string) {
    const items = await this.bookmarkRepo.find({
      where: { userId: user.sub },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    if (!items.length) return { data: [] };

    const postIds = items.map((b) => b.postId);
    const posts = await this.postRepo.find({
      where: { id: In(postIds), deletedAt: IsNull() },
    });
    const postMap = new Map(posts.map((p) => [p.id, p]));

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
      data: items
        .map((b) => {
          const p = postMap.get(b.postId);
          if (!p) return null;
          const author = profileMap.get(p.authorId);
          return {
            bookmark_id: b.id,
            bookmarked_at: b.createdAt.toISOString(),
            post: {
              id: p.id,
              content: p.content,
              media_urls: p.mediaUrls ?? [],
              created_at: p.createdAt.toISOString(),
              author: {
                id: p.authorId,
                full_name: author?.full_name ?? null,
                avatar_url: author?.avatar_url ?? null,
                course: author?.course ?? null,
              },
            },
          };
        })
        .filter(Boolean),
    };
  }

  async listIdsForViewer(postIds: string[], userId: string) {
    if (!postIds.length) return new Set<string>();
    const rows = await this.bookmarkRepo.find({
      where: { userId, postId: In(postIds) },
    });
    return new Set(rows.map((r) => r.postId));
  }
}
