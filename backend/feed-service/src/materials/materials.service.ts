import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { JwtPayload } from '@interaedu/shared';
import { MaterialEntity, MaterialKind } from '../database/entities/material.entity';
import { MaterialRatingEntity } from '../database/entities/material-rating.entity';
import { S3Service } from '../posts/s3.service';
import { GroupsService } from '../groups/groups.service';

const ALLOWED_MIME = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/zip',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'video/mp4',
  'text/plain',
  'text/markdown',
]);

@Injectable()
export class MaterialsService {
  private readonly logger = new Logger(MaterialsService.name);

  constructor(
    @InjectRepository(MaterialEntity)
    private readonly materialRepo: Repository<MaterialEntity>,
    @InjectRepository(MaterialRatingEntity)
    private readonly ratingRepo: Repository<MaterialRatingEntity>,
    private readonly s3: S3Service,
    private readonly groups: GroupsService,
  ) {}

  async upload(
    groupId: string,
    file: Express.Multer.File | undefined,
    body: { title?: string; description?: string },
    user: JwtPayload,
  ) {
    await this.groups.assertMember(groupId, user.sub);
    if (!file) throw new BadRequestException('Arquivo obrigatório');
    if (!ALLOWED_MIME.has(file.mimetype)) {
      throw new BadRequestException(`Tipo de arquivo não suportado: ${file.mimetype}`);
    }
    if (file.size > 50 * 1024 * 1024) {
      throw new BadRequestException('Arquivo maior que 50MB');
    }

    const extension = file.mimetype.split('/')[1] ?? 'bin';
    const key = `materials/${groupId}/${uuidv4()}.${extension}`;
    const url = await this.s3.putObject(key, file.buffer, file.mimetype);

    const title = (body.title ?? file.originalname ?? 'Material').toString().slice(0, 200);
    const material = await this.materialRepo.save({
      groupId,
      uploaderId: user.sub,
      title,
      description: body.description ?? null,
      fileUrl: url,
      fileMime: file.mimetype,
      fileSize: file.size,
      kind: this.kindFromMime(file.mimetype),
    });
    await this.groups.incrementMaterialCount(groupId, 1);

    return { id: material.id, file_url: url };
  }

  async list(groupId: string, user: JwtPayload) {
    await this.groups.assertMember(groupId, user.sub);
    const items = await this.materialRepo.find({
      where: { groupId, deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    return { data: items.map((m) => this.toResponse(m)) };
  }

  async download(id: string, user: JwtPayload) {
    const m = await this.materialRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!m) throw new NotFoundException('Material não encontrado');
    await this.groups.assertMember(m.groupId, user.sub);
    await this.materialRepo.increment({ id: m.id }, 'downloadCount', 1);
    return { url: m.fileUrl };
  }

  async rate(id: string, ratingRaw: number, user: JwtPayload) {
    const rating = Math.max(1, Math.min(5, Number(ratingRaw) || 0));
    if (!rating) throw new BadRequestException('Rating inválido (1-5)');

    const m = await this.materialRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!m) throw new NotFoundException('Material não encontrado');
    await this.groups.assertMember(m.groupId, user.sub);

    const existing = await this.ratingRepo.findOne({
      where: { materialId: id, userId: user.sub },
    });
    if (existing) {
      const delta = rating - existing.rating;
      existing.rating = rating;
      await this.ratingRepo.save(existing);
      await this.materialRepo.increment({ id: m.id }, 'ratingSum', delta);
    } else {
      await this.ratingRepo.save({ materialId: id, userId: user.sub, rating });
      await this.materialRepo.increment({ id: m.id }, 'ratingSum', rating);
      await this.materialRepo.increment({ id: m.id }, 'ratingCount', 1);
    }
    return { message: 'OK' };
  }

  async remove(id: string, user: JwtPayload) {
    const m = await this.materialRepo.findOne({ where: { id, deletedAt: IsNull() } });
    if (!m) throw new NotFoundException('Material não encontrado');
    if (m.uploaderId !== user.sub) {
      throw new ForbiddenException('Apenas quem subiu pode apagar');
    }
    m.deletedAt = new Date();
    await this.materialRepo.save(m);
    await this.groups.incrementMaterialCount(m.groupId, -1);
    return { message: 'OK' };
  }

  private kindFromMime(mime: string): MaterialKind {
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime === 'application/pdf') return 'pdf';
    if (mime.includes('word') || mime === 'text/plain' || mime === 'text/markdown') return 'doc';
    return 'other';
  }

  private toResponse(m: MaterialEntity) {
    const avg = m.ratingCount > 0 ? m.ratingSum / m.ratingCount : 0;
    return {
      id: m.id,
      group_id: m.groupId,
      uploader_id: m.uploaderId,
      title: m.title,
      description: m.description,
      file_url: m.fileUrl,
      file_mime: m.fileMime,
      file_size: m.fileSize,
      kind: m.kind,
      download_count: m.downloadCount,
      rating_avg: Number(avg.toFixed(1)),
      rating_count: m.ratingCount,
      created_at: m.createdAt.toISOString(),
    };
  }
}
