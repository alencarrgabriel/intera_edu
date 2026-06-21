import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { createMultipartProxy } from './proxy/multipart-proxy.middleware';

async function bootstrap() {
  const logger = new Logger('Gateway');
  const app = await NestFactory.create(AppModule, { cors: true });

  // Security
  app.use(helmet());

  // Multipart proxy — precisa rodar antes do body-parser do NestJS para
  // que o stream da requisição esteja intacto. Encaminha multipart/* em
  // raw stream para os serviços downstream.
  app.use(
    createMultipartProxy({
      auth: process.env.AUTH_SERVICE_URL ?? 'http://auth-service:3001',
      profile:
        process.env.PROFILE_SERVICE_URL ?? 'http://profile-service:3002',
      feed: process.env.FEED_SERVICE_URL ?? 'http://feed-service:3003',
      messaging:
        process.env.MESSAGING_SERVICE_URL ?? 'http://messaging-service:3004',
    }),
  );

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Prefix — /metrics fica fora para o Prometheus poder fazer scrape em
  // http://gateway:3000/metrics sem colidir com o catch-all proxy de /api/v1/*.
  app.setGlobalPrefix('api/v1', { exclude: ['/metrics'] });

  const port = process.env.SERVICE_PORT || 3000;
  await app.listen(port);
  logger.log(`API Gateway running on port ${port}`);
}

bootstrap();
