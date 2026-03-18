import { OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
interface RedisOptions {
    host: string;
    port: number;
    password?: string;
}
export declare class RedisService implements OnModuleInit, OnModuleDestroy {
    private readonly options;
    private client;
    private readonly logger;
    constructor(options: RedisOptions);
    onModuleInit(): Promise<void>;
    onModuleDestroy(): Promise<void>;
    getClient(): Redis;
    get(key: string): Promise<string | null>;
    set(key: string, value: string, ttlSeconds?: number): Promise<void>;
    del(key: string): Promise<void>;
    incr(key: string): Promise<number>;
    expire(key: string, ttlSeconds: number): Promise<void>;
    publish(channel: string, message: string): Promise<void>;
}
export {};
