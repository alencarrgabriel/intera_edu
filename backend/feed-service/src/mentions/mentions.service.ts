import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PostMentionEntity, MentionSource } from '../database/entities/post-mention.entity';
import { extractMentions } from '../tags/tag-utils';

const PROFILE_SERVICE_URL = process.env.PROFILE_SERVICE_URL ?? 'http://profile-service:3002';
const MESSAGING_SERVICE_URL = process.env.MESSAGING_SERVICE_URL ?? 'http://messaging-service:3004';

interface MentionContext {
  authorId: string;
  authorName?: string;
  excerpt?: string;
  link?: string;
}

@Injectable()
export class MentionsService {
  private readonly logger = new Logger(MentionsService.name);

  constructor(
    @InjectRepository(PostMentionEntity)
    private readonly mentionRepo: Repository<PostMentionEntity>,
  ) {}

  /// Parses content for @handles, persists mentions and fires notifications.
  /// Best-effort — failures don't crash the parent op.
  async process(
    source: MentionSource,
    sourceId: string,
    content: string,
    context: MentionContext,
    authToken: string,
  ): Promise<string[]> {
    try {
      const handles = extractMentions(content);
      if (!handles.length) return [];

      const resp = await fetch(
        `${PROFILE_SERVICE_URL}/users/by-handles?handles=${handles.join(',')}`,
        { headers: { Authorization: authToken } },
      );
      if (!resp.ok) return [];
      const body = (await resp.json()) as { data: any[] };
      const users = body?.data ?? [];

      const ids: string[] = [];
      for (const u of users) {
        if (u.id === context.authorId) continue;
        ids.push(u.id);
        await this.mentionRepo.save({
          source,
          sourceId,
          mentionedUserId: u.id,
          authorId: context.authorId,
        });
        this.notify(u.id, context, authToken).catch((e) =>
          this.logger.warn(`Notification failed for ${u.id}: ${(e as Error).message}`),
        );
      }
      return ids;
    } catch (err) {
      this.logger.warn(`Mention processing failed: ${(err as Error).message}`);
      return [];
    }
  }

  private async notify(userId: string, ctx: MentionContext, authToken: string) {
    const title = ctx.authorName
      ? `${ctx.authorName} mencionou você`
      : 'Você foi mencionado';
    await fetch(`${MESSAGING_SERVICE_URL}/notifications/internal`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authToken,
      },
      body: JSON.stringify({
        user_id: userId,
        type: 'mention',
        title,
        body: ctx.excerpt ?? null,
        payload: { link: ctx.link, author_id: ctx.authorId },
      }),
    });
  }
}
