# InteraEdu — System Architecture

**Version:** 2.0
**Date:** March 2026

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Flutter App   │  │  Web App     │  │ Admin Panel  │           │
│  │  (Mobile)     │  │  (Future)    │  │  (Future)    │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │        HTTPS/WSS │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (NestJS)                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ Rate     │ │ JWT      │ │ Request  │ │ Circuit  │           │
│  │ Limiter  │ │ Validator│ │ Router   │ │ Breaker  │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
└────────┬──────────┬──────────┬──────────┬───────────────────────┘
         │          │          │          │
    HTTP │     HTTP │     HTTP │     HTTP │
         ▼          ▼          ▼          ▼
  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐
  │  Auth    ││ Profile  ││  Feed    ││Messaging │
  │ Service  ││ Service  ││ Service  ││ Service  │
  │ :3001    ││ :3002    ││ :3003    ││ :3004    │
  └────┬─────┘└────┬─────┘└────┬─────┘└────┬─────┘
       │           │           │           │
       ▼           ▼           ▼           ▼
  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐
  │ auth_db  ││profile_db││ feed_db  ││  msg_db  │
  │(Postgres)││(Postgres)││(Postgres)││(Postgres)│
  └──────────┘└──────────┘└──────────┘└──────────┘
       │           │           │           │
       └───────────┴───────────┴───────────┘
                       │
              ┌────────┴────────┐
              │     Redis       │
              │  (Cache + PubSub│
              │   + Sessions)   │
              └────────┬────────┘
                       │
              ┌────────┴────────┐
              │  Object Storage │
              │  (S3-compat.)   │
              └─────────────────┘
```

> **Note:** In the MVP, all PostgreSQL schemas run within a single PostgreSQL instance using separate schemas per service. In production, each service can be migrated to its own database instance.

---

## 2. Service Boundaries

| Service | Owns | Communicates With |
|:---|:---|:---|
| **API Gateway** | Routing rules, rate limits | All services (HTTP proxy) |
| **Auth Service** | Users credentials, tokens, OTP codes, institutions | Redis (session cache), Profile Service (user creation event) |
| **Profile Service** | User profiles, skills, connections | Auth Service (validates tokens), Feed Service (profile events), Redis (profile cache) |
| **Feed Service** | Posts, reactions, comments | Profile Service (author data), Redis (feed cache) |
| **Messaging Service** | Chats, messages, group memberships | Profile Service (user lookup), Redis (pub/sub for real-time), Object Storage (files) |

---

## 3. Communication Patterns

### 3.1 Synchronous (HTTP/REST)
- **Gateway → Services**: All client requests are proxied via HTTP to the appropriate service.
- **Inter-service queries**: When Service A needs data from Service B during a request, it makes a synchronous HTTP call (e.g., Feed Service fetches author profile from Profile Service).

### 3.2 Asynchronous (Events via Redis Pub/Sub + BullMQ)

Events are published to Redis channels and processed asynchronously by consuming services.

```
Producer Service  ──▶  Redis Channel  ──▶  Consumer Service(s)
```

| Event | Producer | Consumer(s) | Purpose |
|:---|:---|:---|:---|
| `user.registered` | Auth Service | Profile Service | Create initial profile record |
| `user.deleted` | Auth Service | Profile, Feed, Messaging | Cascade anonymization |
| `profile.updated` | Profile Service | Feed Service | Invalidate cached author data |
| `connection.accepted` | Profile Service | Messaging Service | Enable DM channel |
| `connection.removed` | Profile Service | Messaging Service | Close DM if desired |
| `post.created` | Feed Service | Notification Service* | Trigger feed notifications |
| `post.deleted` | Feed Service | — | Invalidate feed cache |
| `message.sent` | Messaging Service | Notification Service* | Trigger push notification |

*Notification Service is a lightweight worker, not a full microservice.

### 3.3 Real-Time (WebSocket)
- **Messaging Service** maintains WebSocket connections for real-time chat.
- WebSocket connections are authenticated via JWT on handshake.
- Multi-instance scaling uses **Redis Pub/Sub** adapter for Socket.IO to fan out messages across Messaging Service replicas.

---

## 4. API Gateway Responsibilities

| Responsibility | Implementation |
|:---|:---|
| **Request Routing** | Route `/api/v1/auth/*` → Auth Service, `/api/v1/users/*` → Profile Service, etc. |
| **Authentication** | Validate JWT on every request (except public endpoints). Reject expired/blacklisted tokens. |
| **Rate Limiting** | Per-IP and per-user limits using Redis sliding window (see Security Architecture). |
| **Request Validation** | Basic schema validation (content-type, required headers). |
| **CORS** | Allow configured origins only. Credentials mode enabled. |
| **Circuit Breaking** | If a downstream service returns 5xx errors > 50% in 30s window, open circuit for 60s. Return 503 to client. |
| **Request ID** | Inject `X-Request-ID` header (UUID) for distributed tracing. |
| **Response Compression** | gzip for responses > 1KB. |

---

## 5. Authentication Flow

```
┌──────┐       ┌─────────┐       ┌────────────┐      ┌───────┐
│Client│       │ Gateway │       │Auth Service│      │ Redis │
└──┬───┘       └────┬────┘       └─────┬──────┘      └───┬───┘
   │                │                   │                  │
   │ POST /auth/register               │                  │
   │ {email}        │                   │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Validate domain  │
   │                │                   │ Generate OTP     │
   │                │                   │ Store OTP────────►
   │                │                   │ Send email       │
   │                │  202 Accepted     │                  │
   │◄───────────────┤◄─────────────────┤                  │
   │                │                   │                  │
   │ POST /auth/verify-otp             │                  │
   │ {email, code}  │                   │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Verify OTP───────►
   │                │                   │ (check Redis)    │
   │                │  {temp_token}     │                  │
   │◄───────────────┤◄─────────────────┤                  │
   │                │                   │                  │
   │ POST /auth/complete-registration  │                  │
   │ {temp_token, password, profile}   │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Create user      │
   │                │                   │ Hash password    │
   │                │                   │ Issue JWT pair   │
   │                │                   │ Store refresh────►
   │                │                   │ Emit user.registered
   │                │  {access, refresh}│                  │
   │◄───────────────┤◄─────────────────┤                  │
```

---

## 6. Feed Generation Pipeline

```
┌──────────────────────────────────────────────────────────┐
│                   Feed Request Flow                        │
│                                                            │
│  1. Client requests GET /posts?scope=global&cursor=xxx    │
│                         │                                  │
│  2. Gateway validates JWT, forwards to Feed Service       │
│                         │                                  │
│  3. Feed Service checks Redis cache                       │
│     ┌───────────────────┴──────────────────┐              │
│     │ Cache HIT                Cache MISS   │              │
│     │ Return cached feed       │            │              │
│     │                   Query PostgreSQL    │              │
│     │                          │            │              │
│     │                   Apply Force Exploration:           │
│     │                   - 80% from user's IES             │
│     │                   - 20% from other IES              │
│     │                          │            │              │
│     │                   Merge + Sort by created_at        │
│     │                          │            │              │
│     │                   Enrich with author profiles       │
│     │                   (batch call to Profile Service)   │
│     │                          │            │              │
│     │                   Cache result in Redis (TTL: 60s)  │
│     │                          │            │              │
│     └──────────────────────────┘            │              │
│                                             │              │
│  4. Return paginated response to client     │              │
└──────────────────────────────────────────────┘
```

### Cache Invalidation Strategy
- **Time-based**: Feed cache TTL = 60 seconds (good enough for social feed).
- **Event-based**: `post.created` and `post.deleted` events invalidate the affected institution's local feed cache key.
- **User-specific**: Global feed cache is keyed by `user_institution_id:cursor` to ensure Force Exploration is personalized.

---

## 7. Messaging Architecture

```
┌────────┐    WSS     ┌──────────────┐    Redis PubSub    ┌──────────────┐
│Client A├───────────►│  Messaging   │◄──────────────────►│  Messaging   │
│        │◄───────────┤  Instance 1  │                    │  Instance 2  │
└────────┘            └──────┬───────┘                    └──────┬───────┘
                             │                                   │    WSS
                             │ Persist                    ┌──────┴───────┐
                             ▼                            │   Client B   │
                      ┌──────────────┐                    └──────────────┘
                      │  msg_db      │
                      │ (PostgreSQL) │
                      └──────────────┘
```

### How it works:
1. Client connects via WebSocket (Socket.IO) with JWT in handshake.
2. Messaging Service authenticates the connection and joins the user to their chat rooms.
3. When Client A sends a message:
   a. Message is persisted to PostgreSQL.
   b. Message is published to Redis Pub/Sub channel `chat:{chat_id}`.
   c. All Messaging Service instances subscribed to that channel relay the message to connected clients in that chat room.
4. If Client B is offline, the message is persisted and a push notification is triggered via the Notification Worker.

### WebSocket Events

| Event | Direction | Payload |
|:---|:---|:---|
| `message:send` | Client → Server | `{ chatId, content, fileUrl? }` |
| `message:new` | Server → Client | `{ messageId, chatId, senderId, content, sentAt }` |
| `message:read` | Client → Server | `{ chatId, lastReadMessageId }` |
| `typing:start` | Client → Server | `{ chatId }` |
| `typing:stop` | Client → Server | `{ chatId }` |
| `typing:indicator` | Server → Client | `{ chatId, userId }` |

---

## 8. Technology Stack (Final Decisions)

| Layer | Technology | Rationale |
|:---|:---|:---|
| **Backend Framework** | NestJS (Node.js + TypeScript) | Enterprise-grade DI, modular architecture, great ecosystem |
| **Mobile App** | Flutter (Dart) | Cross-platform with premium native feel |
| **Database** | PostgreSQL 16 | JSONB, GIN indexes, RLS, mature ecosystem |
| **Cache / Pub-Sub** | Redis 7 | Feed caching, session store, WebSocket fan-out |
| **Job Queue** | BullMQ (Redis-backed) | Email sending, feed generation, data export jobs |
| **Object Storage** | S3-compatible (MinIO for dev, AWS S3 for prod) | File uploads |
| **WebSocket** | Socket.IO (with Redis adapter) | Real-time messaging with automatic reconnection |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Cross-platform push |
| **ORM** | TypeORM | NestJS-native, strong migration support |
| **Container Runtime** | Docker + Docker Compose (dev), Kubernetes (prod) | Consistent environments |
| **CI/CD** | GitHub Actions | Integrated with repository |
| **Monitoring** | Prometheus + Grafana | Metrics collection and dashboards |
| **Logging** | Pino (structured JSON) | High-performance structured logging |
