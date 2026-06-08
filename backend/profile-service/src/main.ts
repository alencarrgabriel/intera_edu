import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('ProfileService');
  // CORS habilitado para suportar upload direto do cliente (ex.: avatar
  // multipart), que o gateway atual não consegue encaminhar.
  const app = await NestFactory.create(AppModule, { cors: true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const port = process.env.SERVICE_PORT || 3002;
  await app.listen(port);
  logger.log(`Profile Service running on port ${port}`);
}
bootstrap();
