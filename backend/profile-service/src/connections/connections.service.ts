import { Injectable, ConflictException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { Connection } from '../database/entities/connection.entity';
import { UserProfile } from '../database/entities/user-profile.entity';
import { CreateConnectionDto } from './dto/create-connection.dto';
import { UpdateConnectionDto } from './dto/update-connection.dto';

@Injectable()
export class ConnectionsService {
  constructor(
    @InjectRepository(Connection)
    private readonly connectionRepo: Repository<Connection>,
    @InjectRepository(UserProfile)
    private readonly userRepo: Repository<UserProfile>,
  ) {}

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
    return { data: connections };
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
    return this.connectionRepo.save(connection);
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

