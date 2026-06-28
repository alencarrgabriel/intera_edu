import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { RedisService } from '@interaedu/shared';
import * as crypto from 'crypto';

const OTP_TTL_SECONDS = 600;        // 10 minutes
const OTP_MAX_ATTEMPTS = 5;
const OTP_COOLDOWN_SECONDS = 900;   // 15 minutes
const OTP_MAX_REQUESTS_PER_HOUR = 3;

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(private readonly redis: RedisService) {}

  async generateAndSend(email: string, purpose: string): Promise<void> {
    // Rate limit: max 3 OTP requests per hour per email
    const requestKey = `otp:requests:${email}`;
    const requestCount = await this.redis.incr(requestKey);
    if (requestCount === 1) {
      await this.redis.expire(requestKey, 3600);
    }
    if (requestCount > OTP_MAX_REQUESTS_PER_HOUR) {
      throw new HttpException('Too many OTP requests. Try again later.', HttpStatus.TOO_MANY_REQUESTS);
    }

    // Generate 6-digit OTP
    const code = crypto.randomInt(100000, 999999).toString();

    // Store in Redis with TTL
    const otpKey = `otp:${purpose}:${email}`;
    const otpData = JSON.stringify({
      code,
      attempts: 0,
      createdAt: Date.now(),
    });
    await this.redis.set(otpKey, otpData, OTP_TTL_SECONDS);

    await this.sendEmail(email, code, purpose);
    this.logger.log(`OTP sent to ${email} (purpose: ${purpose})`);
  }

  private async sendEmail(email: string, code: string, purpose: string): Promise<void> {
    const apiKey = process.env.RESEND_API_KEY;
    const from = process.env.RESEND_FROM ?? 'InteraEdu <onboarding@resend.dev>';

    if (!apiKey) {
      this.logger.warn(`[DEV] OTP for ${email}: ${code}`);
      return;
    }

    const subject = purpose === 'registration'
      ? 'Seu código de verificação — InteraEdu'
      : 'Redefinição de senha — InteraEdu';

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: [email],
        subject,
        html: `<p>Seu código: <strong style="font-size:24px;letter-spacing:4px">${code}</strong></p><p>Válido por 10 minutos.</p>`,
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      this.logger.error(`Resend error ${res.status}: ${body}`);
    }
  }

  async verify(email: string, code: string, purpose: string): Promise<boolean> {
    // Check cooldown
    const cooldownKey = `otp:cooldown:${email}`;
    const cooldown = await this.redis.get(cooldownKey);
    if (cooldown) {
      throw new HttpException('Too many attempts. Try again in 15 minutes.', HttpStatus.TOO_MANY_REQUESTS);
    }

    const otpKey = `otp:${purpose}:${email}`;
    const otpDataStr = await this.redis.get(otpKey);

    if (!otpDataStr) {
      return false; // OTP expired or not found
    }

    const otpData = JSON.parse(otpDataStr);

    // Increment attempts
    otpData.attempts += 1;

    if (otpData.attempts >= OTP_MAX_ATTEMPTS) {
      // Lock out for 15 minutes
      await this.redis.set(cooldownKey, '1', OTP_COOLDOWN_SECONDS);
      await this.redis.del(otpKey);
      throw new HttpException('Too many attempts. Try again in 15 minutes.', HttpStatus.TOO_MANY_REQUESTS);
    }

    if (otpData.code !== code) {
      // Update attempt count
      await this.redis.set(otpKey, JSON.stringify(otpData), OTP_TTL_SECONDS);
      return false;
    }

    // Valid code — delete it (single use)
    await this.redis.del(otpKey);
    return true;
  }
}
