import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  HeadBucketCommand,
  CreateBucketCommand,
  PutBucketPolicyCommand,
} from '@aws-sdk/client-s3';

/// RF-27 — Wrapper S3/MinIO usado pelo messaging-service para anexar
/// arquivos a mensagens. Espelha o S3Service do profile-service —
/// poderíamos extrair para `@interaedu/shared` numa próxima iteração.
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
      forcePathStyle: true,
    });
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch {
      try {
        await this.client.send(new CreateBucketCommand({ Bucket: this.bucket }));
      } catch {
        // ignore — bucket criação concorrente OK
      }
    }
    await this.applyPublicReadPolicy();
  }

  private async applyPublicReadPolicy(): Promise<void> {
    const policy = JSON.stringify({
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: { AWS: ['*'] },
        Action: ['s3:GetObject'],
        Resource: [`arn:aws:s3:::${this.bucket}/*`],
      }],
    });
    try {
      await this.client.send(new PutBucketPolicyCommand({ Bucket: this.bucket, Policy: policy }));
    } catch (err) {
      this.logger.warn(`Could not set bucket policy: ${String(err)}`);
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
