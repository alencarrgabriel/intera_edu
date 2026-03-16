import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DATABASE_HOST', 'localhost'),
        port: config.get<number>('DATABASE_PORT', 5432),
        database: config.get<string>('DATABASE_NAME', 'interaedu'),
        username: config.get<string>('DATABASE_USERNAME', 'interaedu'),
        password: config.get<string>('DATABASE_PASSWORD', ''),
        schema: config.get<string>('DATABASE_SCHEMA', 'public'),
        autoLoadEntities: true,
        synchronize: config.get<string>('NODE_ENV') === 'development',
        ssl: config.get<string>('DATABASE_SSL') === 'true'
          ? { rejectUnauthorized: false }
          : false,
        logging: config.get<string>('NODE_ENV') === 'development',
      }),
    }),
  ],
})
export class DatabaseModule {}
