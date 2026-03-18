import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Gateway');
  const app = await NestFactory.create(AppModule, { cors: true });

  // Security
  app.use(helmet());

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Prefix
  app.setGlobalPrefix('api/v1');

  const port = process.env.SERVICE_PORT || 3000;
  await app.listen(port);
  logger.log(`API Gateway running on port ${port}`);
}

bootstrap();
