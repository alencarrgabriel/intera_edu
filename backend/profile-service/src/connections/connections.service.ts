import { Injectable, ConflictException, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull, In, DataSource } from 'typeorm';
import { Connection } from '../database/entities/connection.entity';
import { UserProfile } from '../database/entities/user-profile.entity';
import { CreateConnectionDto } from './dto/create-connection.dto';
import { UpdateConnectionDto } from './dto/update-connection.dto';

@Injectable()
export class ConnectionsService {
  private readonly logger = new Logger(ConnectionsService.name);
  private readonly messagingUrl = process.env.MESSAGING_SERVICE_URL ?? 'http://messaging-service:3004';

  constructor(
    @InjectRepository(Connection)
    private readonly connectionRepo: Repository<Connection>,
    @InjectRepository(UserProfile)
    private readonly userRepo: Repository<UserProfile>,
    private readonly dataSource: DataSource,
  ) {}

  private async notify(userId: string, type: string, title: string, body: string): Promise<void> {
    try {
      await fetch(`${this.messagingUrl}/notifications/internal`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId, type, title, body }),
      });
    } catch (e) {
      this.logger.warn(`Failed to send notification: ${e}`);
    }
  }

  async list(userId: string, status?: string, direction?: string) {
    const where: any[] = [];

    if (status === 'pending') {
      if (direction === 'received') where.push({ addresseeId: userId, status: 'pending' });
      else if (direction === 'sent') where.push({ requesterId: userId, status: 'pending' });
      else where.push({ requesterId: userId, status: 'pending' }, { addresseeId: userId, status: 'pending' });
    } else if (status === 'accepted') {
      where.push({ requesterId: userId, status: 'accepted' }, { addresseeId: userId, status: 'accepted' });
    } else {
      where.push({ requesterId: userId }, { addresseeId: userId });
    }

    const connections = await this.connectionRepo.find({ where, order: { requestedAt: 'DESC' }, take: 200 });

    // Enriquece com dados do "outro usuário" para que o cliente possa
    // renderizar nome / curso / avatar sem N+1 requests.
    const otherIds = Array.from(
      new Set(
        connections.map((c) =>
          c.requesterId === userId ? c.addresseeId : c.requesterId,
        ),
      ),
    );

    const profiles =
      otherIds.length > 0
        ? await this.userRepo.find({
            where: { id: In(otherIds), deletedAt: IsNull() },
          })
        : [];
    const profileById = new Map(profiles.map((p) => [p.id, p]));

    // Carrega nomes de instituições em uma única query (cross-schema OK).
    const institutionIds = Array.from(
      new Set(profiles.map((p) => p.institutionId).filter(Boolean)),
    );
    const institutions: Array<{ id: string; name: string; slug: string | null }> =
      institutionIds.length === 0
        ? []
        : await this.dataSource.query(
            `SELECT id, name, slug FROM auth.institutions WHERE id = ANY($1::uuid[])`,
            [institutionIds],
          );
    const instById = new Map(institutions.map((i) => [i.id, i]));

    const data = connections.map((c) => {
      const otherId = c.requesterId === userId ? c.addresseeId : c.requesterId;
      const dir = c.requesterId === userId ? 'sent' : 'received';
      const p = profileById.get(otherId);
      const inst = p ? instById.get(p.institutionId) : null;
      return {
        id: c.id,
        status: c.status,
        direction: dir,
        created_at: c.requestedAt,
        responded_at: c.respondedAt,
        other_user: p
          ? {
              id: p.id,
              full_name: p.fullName,
              course: p.course,
              avatar_url: p.avatarUrl,
              institution: inst
                ? { id: inst.id, name: inst.name, slug: inst.slug }
                : null,
            }
          : null,
      };
    });

    return { data };
  }

  async create(requesterId: string, dto: CreateConnectionDto) {
    if (requesterId === dto.addressee_id) throw new ForbiddenException('Cannot connect to yourself.');

    const addressee = await this.userRepo.findOne({
      where: { id: dto.addressee_id, deletedAt: IsNull() },
    });
    if (!addressee) throw new NotFoundException('User not found');

    const existing = await this.connectionRepo.findOne({
      where: [
        { requesterId, addresseeId: dto.addressee_id },
        { requesterId: dto.addressee_id, addresseeId: requesterId },
      ],
    });
    if (existing) throw new ConflictException('Connection request already exists.');

    const connection = await this.connectionRepo.save({
      requesterId,
      addresseeId: dto.addressee_id,
      status: 'pending',
    });

    const requester = await this.userRepo.findOne({ where: { id: requesterId, deletedAt: IsNull() } });
    const requesterName = requester?.fullName ?? 'Alguém';
    void this.notify(
      dto.addressee_id,
      'connection_request',
      'Nova solicitação de conexão',
      `${requesterName} quer se conectar com você`,
    );

    return connection;
  }

  async update(actorId: string, connectionId: string, dto: UpdateConnectionDto) {
    const connection = await this.connectionRepo.findOne({ where: { id: connectionId } });
    if (!connection) throw new NotFoundException('Connection not found');

    if (connection.addresseeId !== actorId) {
      throw new ForbiddenException('Only the addressee can respond to a connection request.');
    }
    if (connection.status !== 'pending') {
      throw new ConflictException('Connection request already resolved.');
    }

    connection.status = dto.action === 'accept' ? 'accepted' : 'rejected';
    connection.respondedAt = new Date();
    const saved = await this.connectionRepo.save(connection);

    if (dto.action === 'accept') {
      const accepter = await this.userRepo.findOne({ where: { id: actorId, deletedAt: IsNull() } });
      const accepterName = accepter?.fullName ?? 'Alguém';
      void this.notify(
        connection.requesterId,
        'connection_accepted',
        'Conexão aceita',
        `${accepterName} aceitou sua solicitação de conexão`,
      );
    }

    return saved;
  }

  async remove(actorId: string, connectionId: string) {
    const connection = await this.connectionRepo.findOne({ where: { id: connectionId } });
    if (!connection) throw new NotFoundException('Connection not found');

    if (connection.requesterId !== actorId && connection.addresseeId !== actorId) {
      throw new ForbiddenException('Not allowed.');
    }

    await this.connectionRepo.delete({ id: connectionId });
  }
}

