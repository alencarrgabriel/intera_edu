import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan, In } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { JwtPayload } from '@interaedu/shared';
import { StoryEntity } from '../database/entities/story.entity';
import { StoryViewEntity } from '../database/entities/story-view.entity';
import { S3Service } from '../posts/s3.service';

const PROFILE_SERVICE_URL = process.env.PROFILE_SERVICE_URL ?? 'http://profile-service:3002';
const TTL_HOURS = 24;
const ALLOWED_MIME = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
]);

@Injectable()
export class StoriesService {
  constructor(
    @InjectRepository(StoryEntity)
    private readonly storyRepo: Repository<StoryEntity>,
    @InjectRepository(StoryViewEntity)
    private readonly viewRepo: Repository<StoryViewEntity>,
    private readonly s3: S3Service,
  ) {}

  async create(
    file: Express.Multer.File | undefined,
    body: { caption?: string },
    user: JwtPayload,
  ) {
    if (!file) throw new BadRequestException('Mídia obrigatória');
    if (!ALLOWED_MIME.has(file.mimetype)) {
      throw new BadRequestException('Tipo de arquivo não suportado');
    }
    if (file.size > 25 * 1024 * 1024) {
      throw new BadRequestException('Mídia maior que 25MB');
    }
    const ext = file.mimetype.split('/')[1] ?? 'bin';
    const key = `stories/${user.sub}/${uuidv4()}.${ext}`;
    const url = await this.s3.putObject(key, file.buffer, file.mimetype);

    const story = await this.storyRepo.save({
      authorId: user.sub,
      institutionId: user.institution_id,
      mediaUrl: url,
      mediaMime: file.mimetype,
      caption: body.caption ?? null,
      expiresAt: new Date(Date.now() + TTL_HOURS * 60 * 60 * 1000),
    });
    return { id: story.id };
  }

  async listActive(user: JwtPayload, authToken: string) {
    const now = new Date();
    const items = await this.storyRepo.find({
      where: {
        institutionId: user.institution_id,
        expiresAt: MoreThan(now),
      },
      order: { createdAt: 'DESC' },
      take: 200,
    });

    const authorIds = [...new Set(items.map((s) => s.authorId))];
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

    const ids = items.map((s) => s.id);
    const myViews = await this.viewRepo.find({
      where: { storyId: In(ids), userId: user.sub },
    });
    const viewedSet = new Set(myViews.map((v) => v.storyId));

    const groups = new Map<string, any[]>();
    items.forEach((s) => {
      const arr = groups.get(s.authorId) ?? [];
      arr.push({
        id: s.id,
        media_url: s.mediaUrl,
        media_mime: s.mediaMime,
        caption: s.caption,
        view_count: s.viewCount,
        viewed: viewedSet.has(s.id),
        created_at: s.createdAt.toISOString(),
        expires_at: s.expiresAt.toISOString(),
      });
      groups.set(s.authorId, arr);
    });

    return {
      data: Array.from(groups.entries()).map(([authorId, stories]) => ({
        author: {
          id: authorId,
          full_name: profileMap.get(authorId)?.full_name ?? null,
          avatar_url: profileMap.get(authorId)?.avatar_url ?? null,
        },
        all_viewed: stories.every((s: any) => s.viewed),
        stories,
      })),
    };
  }

  async markViewed(storyId: string, user: JwtPayload) {
    const s = await this.storyRepo.findOne({ where: { id: storyId } });
    if (!s) throw new NotFoundException('Story não encontrado');
    const existing = await this.viewRepo.findOne({
      where: { storyId, userId: user.sub },
    });
    if (!existing) {
      await this.viewRepo.save({ storyId, userId: user.sub });
      await this.storyRepo.increment({ id: storyId }, 'viewCount', 1);
    }
    return { message: 'OK' };
  }

  async myStories(user: JwtPayload) {
    const items = await this.storyRepo.find({
      where: { authorId: user.sub, expiresAt: MoreThan(new Date()) },
      order: { createdAt: 'DESC' },
    });
    return {
      data: items.map((s) => ({
        id: s.id,
        media_url: s.mediaUrl,
        caption: s.caption,
        view_count: s.viewCount,
        created_at: s.createdAt.toISOString(),
        expires_at: s.expiresAt.toISOString(),
      })),
    };
  }

  async deleteStory(id: string, user: JwtPayload) {
    const s = await this.storyRepo.findOne({ where: { id } });
    if (!s) throw new NotFoundException('Story não encontrado');
    if (s.authorId !== user.sub) {
      throw new BadRequestException('Só o autor pode apagar');
    }
    await this.storyRepo.remove(s);
    return { message: 'OK' };
  }
}
