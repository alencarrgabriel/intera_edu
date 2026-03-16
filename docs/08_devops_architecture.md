# InteraEdu — DevOps Architecture

**Version:** 2.0
**Date:** March 2026

---

## 1. Container Structure

### 1.1 Service Containers

| Container | Base Image | Port | Purpose |
|:---|:---|:---|:---|
| `gateway` | `node:20-alpine` | 3000 | API Gateway (NestJS) |
| `auth-service` | `node:20-alpine` | 3001 | Authentication Service |
| `profile-service` | `node:20-alpine` | 3002 | Profile Service |
| `feed-service` | `node:20-alpine` | 3003 | Feed Service |
| `messaging-service` | `node:20-alpine` | 3004 | Messaging Service |

### 1.2 Infrastructure Containers

| Container | Image | Port | Purpose |
|:---|:---|:---|:---|
| `postgres` | `postgres:16-alpine` | 5432 | Primary database |
| `redis` | `redis:7-alpine` | 6379 | Cache, pub/sub, sessions |
| `minio` | `minio/minio` | 9000 | S3-compatible object storage (dev) |

### 1.3 Dockerfile Template (per service)

```dockerfile
# Multi-stage build for production
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

---

## 2. CI/CD Pipeline

### 2.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [gateway, auth-service, profile-service, feed-service, messaging-service]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
          cache-dependency-path: backend/${{ matrix.service }}/package-lock.json
      - run: cd backend/${{ matrix.service }} && npm ci
      - run: cd backend/${{ matrix.service }} && npm run lint
      - run: cd backend/${{ matrix.service }} && npm run test
      - run: cd backend/${{ matrix.service }} && npm run test:e2e

  build-and-push:
    needs: lint-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [gateway, auth-service, profile-service, feed-service, messaging-service]
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: backend/${{ matrix.service }}
          push: true
          tags: ghcr.io/${{ github.repository }}/${{ matrix.service }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to staging
        run: echo "Deploy to staging K8s cluster"
        # kubectl apply / helm upgrade

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy to production
        run: echo "Deploy to production K8s cluster"
```

### 2.2 Pipeline Stages

```
Code Push → Lint → Unit Tests → E2E Tests → Build Docker → Push to Registry
                                                              │
                                            ┌─────────────────┴─────────────────┐
                                            │                                   │
                                    Deploy Staging                      Deploy Production
                                    (automatic)                         (manual approval)
```

---

## 3. Environment Strategy

### 3.1 Environments

| Environment | Purpose | Infrastructure | Branch |
|:---|:---|:---|:---|
| **Local** | Developer workstation | Docker Compose | Any |
| **CI** | Automated testing | GitHub Actions runners | PR branches |
| **Staging** | Pre-production validation | Cloud (scaled down) | `main` (auto) |
| **Production** | Live system | Cloud (full scale) | `main` (manual approve) |

### 3.2 Environment Variables

All services share a common `.env` structure:

```bash
# Application
NODE_ENV=development          # development | staging | production
SERVICE_NAME=auth-service
SERVICE_PORT=3001

# Database
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=interaedu
DATABASE_USERNAME=interaedu
DATABASE_PASSWORD=secret
DATABASE_SCHEMA=auth
DATABASE_SSL=false

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_ACCESS_SECRET=your-access-secret-here
JWT_REFRESH_SECRET=your-refresh-secret-here
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# Email (for OTP)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-key

# S3 (Object Storage)
S3_ENDPOINT=http://minio:9000
S3_BUCKET=interaedu
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_REGION=us-east-1

# Firebase (Push Notifications)
FIREBASE_PROJECT_ID=interaedu
FIREBASE_CREDENTIALS_PATH=./firebase-key.json
```

---

## 4. Secrets Management

### 4.1 Strategy by Environment

| Environment | Secrets Storage |
|:---|:---|
| Local | `.env` file (gitignored) |
| CI | GitHub Secrets |
| Staging/Production | Cloud KMS (AWS Secrets Manager / GCP Secret Manager) |

### 4.2 Sensitive Secrets

| Secret | Used By |
|:---|:---|
| `JWT_ACCESS_SECRET` | Auth Service, Gateway |
| `JWT_REFRESH_SECRET` | Auth Service |
| `DATABASE_PASSWORD` | All services |
| `REDIS_PASSWORD` | All services |
| `SMTP_PASSWORD` | Auth Service |
| `S3_SECRET_KEY` | Feed Service, Messaging Service |
| `FIREBASE_CREDENTIALS` | Messaging Service (push notifications) |

### 4.3 Secret Rotation
- JWT secrets: Rotate quarterly. Support dual-key validation during rotation window.
- Database passwords: Rotate monthly in production.
- API keys (SendGrid, Firebase): Rotate on team member departure.

---

## 5. Monitoring & Observability

### 5.1 Metrics (Prometheus)

Each NestJS service exposes a `/metrics` endpoint (via `@willsoto/nestjs-prometheus`).

**Key Metrics:**

| Metric | Type | Description |
|:---|:---|:---|
| `http_requests_total` | Counter | Total HTTP requests by method, route, status |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `active_websocket_connections` | Gauge | Current WebSocket connections |
| `database_query_duration_seconds` | Histogram | DB query latency |
| `redis_operations_total` | Counter | Redis operations by command |
| `auth_login_attempts_total` | Counter | Login attempts by success/failure |
| `otp_verification_attempts_total` | Counter | OTP attempts by success/failure |
| `feed_cache_hits_total` | Counter | Feed cache hit/miss ratio |

### 5.2 Dashboards (Grafana)

| Dashboard | Panels |
|:---|:---|
| **Service Health** | Request rate, error rate, latency (p50/p95/p99), uptime |
| **Authentication** | Login rate, OTP success rate, token refresh rate, blocked IPs |
| **Feed Performance** | Feed load time, cache hit ratio, post creation rate |
| **Messaging** | WebSocket connections, message throughput, delivery latency |
| **Infrastructure** | CPU/Memory per container, PostgreSQL connections, Redis memory |

### 5.3 Logging

**Structured JSON logs** via Pino:

```json
{
  "level": "info",
  "time": "2026-03-15T10:30:00.000Z",
  "service": "auth-service",
  "request_id": "uuid",
  "user_id": "uuid",
  "method": "POST",
  "path": "/auth/login",
  "status": 200,
  "duration_ms": 45,
  "message": "Login successful"
}
```

**Log Levels by Environment:**

| Environment | Level |
|:---|:---|
| Local | `debug` |
| Staging | `info` |
| Production | `warn` |

### 5.4 Distributed Tracing

- **OpenTelemetry SDK** integrated into each service.
- **Trace propagation** via `traceparent` header (W3C Trace Context).
- **Export to**: Jaeger (dev) or cloud-native tracing (AWS X-Ray / GCP Cloud Trace).

### 5.5 Alerting

| Alert | Condition | Severity | Channel |
|:---|:---|:---|:---|
| High error rate | >5% 5xx responses in 5 min | Critical | PagerDuty / Slack |
| High latency | p95 > 5s for 5 min | Warning | Slack |
| DB connection pool exhausted | Active connections > 90% | Critical | PagerDuty |
| Auth lockout spike | >50 lockouts in 10 min | Warning | Slack |
| Disk usage | >80% on any volume | Warning | Slack |

### 5.6 Health Checks

Each service exposes:

| Endpoint | Purpose |
|:---|:---|
| `GET /health` | Liveness probe (returns 200 if process is alive) |
| `GET /health/ready` | Readiness probe (checks DB + Redis connectivity) |
