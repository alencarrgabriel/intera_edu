import { Injectable, Logger, TooManyRequestsException } from '@nestjs/common';
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
      throw new TooManyRequestsException('Too many OTP requests. Try again later.');
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

    // TODO: Send email via SMTP/SendGrid
    // For development, log the code
    this.logger.log(`[DEV] OTP for ${email}: ${code}`);
  }

  async verify(email: string, code: string, purpose: string): Promise<boolean> {
    // Check cooldown
    const cooldownKey = `otp:cooldown:${email}`;
    const cooldown = await this.redis.get(cooldownKey);
    if (cooldown) {
      throw new TooManyRequestsException('Too many attempts. Try again in 15 minutes.');
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
      throw new TooManyRequestsException('Too many attempts. Try again in 15 minutes.');
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
