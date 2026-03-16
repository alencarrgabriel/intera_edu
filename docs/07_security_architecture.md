# InteraEdu — Security Architecture

**Version:** 2.0
**Date:** March 2026

---

## 1. Authentication Flow

### 1.1 JWT Strategy

| Token | Lifetime | Storage | Purpose |
|:---|:---|:---|:---|
| **Access Token** | 15 minutes | In-memory (mobile app state) | API authentication |
| **Refresh Token** | 7 days | Secure storage (Flutter `flutter_secure_storage`) | Obtain new access tokens |
| **Temporary Token** | 15 minutes | In-memory | OTP-verified registration completion |

### 1.2 Access Token Payload (JWT Claims)

```json
{
  "sub": "uuid-user-id",
  "iss": "interaedu-auth",
  "iat": 1711234567,
  "exp": 1711235467,
  "institution_id": "uuid-institution",
  "email": "ana@aluno.ufmg.br",
  "roles": ["user"]
}
```

### 1.3 Refresh Token Rotation
- On each `/auth/refresh` call, the old refresh token is **revoked** and a new one is issued.
- If a revoked refresh token is used again (replay attack), **all** refresh tokens for that user are revoked (family invalidation).
- Refresh tokens are stored as **bcrypt hashes** in `auth.refresh_tokens`.

### 1.4 Token Revocation
- **Logout**: The specific refresh token is revoked.
- **Password change**: All refresh tokens for the user are revoked.
- **Account deletion**: All tokens revoked.
- **Blacklist check**: Access tokens are short-lived (15 min), so no blacklist is needed for access tokens. Refresh token revocation is checked at the database level.

---

## 2. OTP Protection

### 2.1 OTP Generation
- 6-digit numeric code.
- Generated using `crypto.randomInt(100000, 999999)` (cryptographically secure).
- Stored as **bcrypt hash** in `auth.otp_codes` and in Redis with 10-minute TTL.

### 2.2 Rate Limiting

| Limit | Value | Window |
|:---|:---|:---|
| OTP verification attempts | 5 attempts | Per email, per 15 minutes |
| OTP request (send new code) | 3 requests | Per email, per hour |
| Failed login attempts | 10 attempts | Per IP, per 15 minutes |
| After lockout | Blocked | 15 minutes cooldown |

### 2.3 Brute Force Mitigation
- After 5 failed OTP attempts → 15-minute lockout (tracked in Redis).
- After 3 consecutive lockouts → Account flagged for manual review.
- OTP codes are single-use (marked as `used_at` after verification).
- Exponential backoff: Response time increases with each failed attempt (100ms, 200ms, 400ms...) to deter automated attacks.

---

## 3. API Rate Limiting

### 3.1 Strategy
Rate limiting uses a **Redis sliding window** algorithm at the API Gateway.

### 3.2 Limits

| Endpoint Category | Limit | Window | Key |
|:---|:---|:---|:---|
| Public endpoints (register, login) | 20 requests | 1 minute | Per IP |
| Authenticated read endpoints | 100 requests | 1 minute | Per user |
| Authenticated write endpoints | 30 requests | 1 minute | Per user |
| File uploads | 10 requests | 1 hour | Per user |
| Search | 30 requests | 1 minute | Per user |
| WebSocket connections | 5 concurrent | — | Per user |

### 3.3 Response Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1711234627
```

### 3.4 Rate Limit Exceeded Response
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Try again in 43 seconds.",
    "status": 429,
    "retry_after": 43
  }
}
```

---

## 4. Abuse Protection

### 4.1 Input Validation
- All request bodies validated via NestJS `class-validator` DTOs.
- HTML/script injection prevented via output sanitization (DOMPurify for any rendered content).
- SQL injection prevented via TypeORM parameterized queries (never raw string concatenation).
- File uploads validated: file type by magic bytes (not just extension), size limit enforced.

### 4.2 Content Abuse
- **Reporting**: Users can report posts, comments, messages, and profiles.
- **Moderation Queue**: Reports go to admin panel for manual review.
- **Rate limiting on content creation**: Max 10 posts/hour, 50 comments/hour per user.

### 4.3 Account Abuse
- Disposable email domain detection (block known disposable email providers).
- One account per institutional email (enforced by UNIQUE constraint).
- Account suspension capability for admins.

---

## 5. Privacy Masking Logic

### 5.1 Visibility Matrix

| Viewer's Relation | Target Privacy: `public` | Target: `local_only` | Target: `private` |
|:---|:---|:---|:---|
| Same institution | ✅ Full profile | ✅ Full profile | ❌ Hidden |
| Different institution, not connected | ✅ Full profile | ❌ Hidden | ❌ Hidden |
| Different institution, connected | ✅ Full profile | ✅ Full profile | ✅ Full profile |
| Blocked by target | ❌ Hidden | ❌ Hidden | ❌ Hidden |

### 5.2 Implementation
Privacy masking is enforced at two levels:
1. **Database level**: PostgreSQL RLS policies filter queries based on the requesting user's `institution_id` and connection status.
2. **Application level**: Profile Service applies privacy checks before returning data.

### 5.3 Search Visibility
Search results **exclude** profiles that the requesting user cannot see. The search query includes a JOIN to check privacy and connection status.

---

## 6. Data Encryption

### 6.1 In Transit
- **TLS 1.3** enforced on all connections (API, WebSocket, database, Redis).
- HSTS headers with 1-year max-age.
- Certificate pinning in the Flutter mobile app for production.

### 6.2 At Rest
- **PostgreSQL**: Encryption at rest via disk-level encryption (AWS EBS / GCP Persistent Disk encryption).
- **S3 files**: Server-side encryption (SSE-S3 or SSE-KMS).
- **Passwords**: bcrypt with cost factor 12.
- **OTP codes**: bcrypt hashed.
- **Refresh tokens**: SHA-256 hashed in database; only the hash is stored.

### 6.3 Sensitive Fields
| Field | Protection |
|:---|:---|
| `password_hash` | bcrypt (cost 12) |
| OTP codes | bcrypt in DB, Redis TTL |
| Refresh tokens | SHA-256 hash stored |
| Email addresses | Stored in plaintext (needed for authentication); access-controlled by RLS |
| IP addresses (audit) | Stored for 5 years per LGPD audit requirements |

> **Note:** True end-to-end encryption for messages is NOT implemented in the MVP. Messages are encrypted in transit (TLS) and at rest (disk encryption), but are readable by the server for moderation purposes. E2E encryption would prevent content moderation and search functionality.

---

## 7. Password Policy

| Requirement | Value |
|:---|:---|
| Minimum length | 8 characters |
| Maximum length | 128 characters |
| Required character classes | 1 uppercase, 1 lowercase, 1 number, 1 special character |
| Breached password check | Check against HaveIBeenPwned API (k-anonymity model) |
| Password history | Cannot reuse last 3 passwords |
| Hashing algorithm | bcrypt, cost factor 12 |

---

## 8. CORS Policy

```typescript
// API Gateway CORS configuration
{
  origin: [
    'https://app.interaedu.com',
    'https://admin.interaedu.com',
    // Development
    'http://localhost:3000',
    'http://localhost:8080',
  ],
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type', 'X-Request-ID', 'X-Idempotency-Key'],
  credentials: true,
  maxAge: 86400, // 24 hours
}
```

---

## 9. Security Headers

All responses include:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

## 10. Threat Model Summary

| Threat | Mitigation |
|:---|:---|
| Credential stuffing | Rate limiting + account lockout |
| OTP brute force | 5-attempt limit + 15-min coolout |
| Token theft | Short-lived access tokens + refresh rotation |
| Replay attacks | Refresh token family invalidation |
| XSS | Input validation + CSP headers |
| SQL injection | Parameterized queries (TypeORM) |
| CSRF | SameSite cookies + token-based auth |
| Data leakage | RLS + privacy masking at app layer |
| File upload attacks | Type validation (magic bytes) + AV scanning (future) |
| DDoS | Rate limiting + WAF (production) |
