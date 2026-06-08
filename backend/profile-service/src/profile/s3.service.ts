import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  HeadBucketCommand,
  CreateBucketCommand,
} from '@aws-sdk/client-s3';

/**
 * Wraps the S3-compatible storage (MinIO em dev, S3 em produção).
 *
 * `S3_ENDPOINT` é o endpoint usado pelo backend para fazer upload — em dev
 * aponta para o serviço interno `minio:9000`. `S3_PUBLIC_ENDPOINT` é a URL
 * usada para montar o link público devolvido ao cliente — em dev aponta
 * para `localhost:9000` (acessível pelo navegador do usuário).
 */
@Injectable()
export class S3Service implements OnModuleInit {
  private readonly logger = new Logger(S3Service.name);
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicEndpoint: string;

  constructor() {
    const endpoint = process.env.S3_ENDPOINT ?? 'http://minio:9000';
    this.bucket = process.env.S3_BUCKET ?? 'interaedu';
    this.publicEndpoint = process.env.S3_PUBLIC_ENDPOINT ?? endpoint;
    this.client = new S3Client({
      endpoint,
      region: process.env.S3_REGION ?? 'us-east-1',
      credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY ?? 'minioadmin',
        secretAccessKey: process.env.S3_SECRET_KEY ?? 'minioadmin',
      },
      // MinIO requer path-style addressing
      forcePathStyle: true,
    });
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
      this.logger.log(`Bucket "${this.bucket}" já existe`);
    } catch {
      try {
        await this.client.send(new CreateBucketCommand({ Bucket: this.bucket }));
        this.logger.log(`Bucket "${this.bucket}" criado`);
      } catch (err) {
        this.logger.warn(`Não foi possível garantir o bucket: ${String(err)}`);
      }
    }
  }

  async putObject(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<string> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
    return `${this.publicEndpoint}/${this.bucket}/${key}`;
  }
}
