# InteraEdu — Scalability Strategy

**Version:** 2.0
**Date:** March 2026

---

## 1. Scaling Roadmap

| Stage | Users | Architecture | Key Actions |
|:---|:---|:---|:---|
| **MVP** | 0 – 10K | Single instance per service, shared PostgreSQL | Docker Compose, basic Redis caching |
| **Growth** | 10K – 100K | Multi-instance services, read replicas | Horizontal pod scaling, connection pooling, search index |
| **Scale** | 100K – 1M+ | Full Kubernetes, dedicated DB per service | Database sharding, CDN, Elasticsearch cluster |

---

## 2. Feed Caching Strategy

### 2.1 Cache Architecture

```
Client Request
     │
     ▼
┌──────────┐    Cache Key: feed:{scope}:{institution_id}:{cursor_hash}
│ Feed     │──────────────────────────────► Redis Cache
│ Service  │                                    │
│          │◄───────────────────────────────────┤ HIT → Return cached feed
│          │                                    │ MISS ↓
│          │    Query PostgreSQL                 │
│          │──────────────────────────────► PostgreSQL
│          │◄──────────────────────────────     │
│          │    Apply Force Exploration          │
│          │    Cache result (TTL: 60s) ────────► Redis Cache
│          │                                    │
│          │    Return to client                │
└──────────┘
```

### 2.2 Cache Keys

| Key Pattern | TTL | Invalidation |
|:---|:---|:---|
| `feed:local:{institution_id}:{cursor}` | 60s | On `post.created/deleted` for that institution |
| `feed:global:{institution_id}:{cursor}` | 60s | On any `post.created/deleted` |
| `profile:{user_id}` | 300s | On `profile.updated` |
| `user:connections:{user_id}` | 600s | On `connection.accepted/removed` |
| `skills:taxonomy` | 3600s | On admin skill update |
| `institution:domains` | 3600s | On admin domain update |

### 2.3 Cache Warming
- On service startup, pre-load the skill taxonomy and institution domains into Redis.
- For popular institutions (top 10 by user count), pre-generate and cache the local feed.

---

## 3. Redis Usage Map

| Use Case | Redis Data Structure | Details |
|:---|:---|:---|
| **Feed cache** | String (JSON) | Serialized feed pages, TTL-based expiry |
| **Session/OTP storage** | String | OTP codes with 10-minute TTL |
| **Rate limiting** | Sorted Set (sliding window) | Score = timestamp, member = request ID |
| **WebSocket pub/sub** | Pub/Sub channels | Channel per chat room: `chat:{chat_id}` |
| **Online presence** | Set | `online_users` set with periodic cleanup |
| **Token blacklist** | Set | `blacklisted_tokens` for emergency revocation |
| **User typing indicators** | String (TTL) | `typing:{chat_id}:{user_id}` with 5-second TTL |

### 3.1 Redis Memory Estimation (100K Users)

| Data | Estimated Size |
|:---|:---|
| Feed cache (top 1000 feeds) | ~50 MB |
| Active sessions / OTPs | ~5 MB |
| Rate limit windows | ~10 MB |
| Online presence set | ~2 MB |
| Token blacklist | ~1 MB |
| **Total** | **~70 MB** |

---

## 4. Message Queue Strategy

### 4.1 BullMQ (Redis-backed Job Queue)

BullMQ handles asynchronous background jobs:

| Queue | Jobs | Priority | Concurrency |
|:---|:---|:---|:---|
| `email` | OTP delivery, notifications, data export links | High | 5 workers |
| `feed-invalidation` | Cache invalidation on post changes | High | 3 workers |
| `data-export` | LGPD data export generation | Low | 1 worker |
| `cleanup` | Purge expired OTPs, revoked tokens, soft-deleted data | Low | 1 worker |
| `notifications` | Push notification dispatch (FCM) | Medium | 3 workers |
| `anonymization` | Account deletion anonymization cascade | Low | 1 worker |

### 4.2 Job Retry Strategy

| Queue | Max Retries | Backoff | Dead Letter |
|:---|:---|:---|:---|
| `email` | 3 | Exponential (1s, 4s, 16s) | Yes |
| `feed-invalidation` | 2 | Fixed (500ms) | No (best effort) |
| `data-export` | 3 | Exponential (30s, 120s, 480s) | Yes |
| `notifications` | 2 | Exponential (1s, 4s) | Yes |
| `anonymization` | 5 | Exponential (60s, 240s, ...) | Yes (alerts) |

### 4.3 Future Migration Path: Apache Kafka
When the system handles >10K events/second (estimated at ~500K MAU), migrate from BullMQ to Kafka for:
- Event sourcing capability
- Multi-consumer support (same event consumed by multiple services)
- Event replay for debugging
- Higher throughput

---

## 5. Search Indexing Strategy

### 5.1 Phase 1 (MVP): PostgreSQL Native

```sql
-- User search: GIN + tsvector
SELECT u.id, u.full_name, u.course, u.institution_id
FROM profile.users u
JOIN profile.user_skills us ON u.id = us.user_id
JOIN profile.skills s ON us.skill_id = s.id
WHERE s.slug = 'python'
  AND u.institution_id = 'uuid-usp'
  AND u.privacy_level = 'public'
  AND u.deleted_at IS NULL
ORDER BY u.created_at DESC
LIMIT 20;

-- Full-text name search
SELECT * FROM profile.users
WHERE to_tsvector('portuguese', full_name) @@ plainto_tsquery('portuguese', 'Ana Silva')
  AND deleted_at IS NULL;
```

Expected performance: <100ms for up to 500K users with proper indexes.

### 5.2 Phase 2 (Scale): Elasticsearch

When PostgreSQL full-text search becomes a bottleneck (>500K users or complex queries):

```
PostgreSQL ──(CDC via Debezium)──► Kafka ──► Elasticsearch
                                              │
API Query ──────────────────────────────────► ES Cluster
                                              │
                                        Return results
```

**Elasticsearch index mappings:**

```json
{
  "users": {
    "properties": {
      "full_name": { "type": "text", "analyzer": "portuguese" },
      "skills": { "type": "keyword" },
      "course": { "type": "keyword" },
      "institution_id": { "type": "keyword" },
      "privacy_level": { "type": "keyword" }
    }
  },
  "posts": {
    "properties": {
      "content": { "type": "text", "analyzer": "portuguese" },
      "institution_id": { "type": "keyword" },
      "scope": { "type": "keyword" },
      "created_at": { "type": "date" }
    }
  }
}
```

---

## 6. Horizontal Scaling

### 6.1 Service Scaling Targets

| Service | Min Replicas | Max Replicas | Scale Trigger |
|:---|:---|:---|:---|
| Gateway | 2 | 10 | CPU > 70% or RPS > 500/instance |
| Auth Service | 2 | 5 | CPU > 70% |
| Profile Service | 2 | 8 | CPU > 70% or RPS > 300/instance |
| Feed Service | 2 | 10 | CPU > 70% or p95 latency > 1s |
| Messaging Service | 2 | 15 | WebSocket connections > 5K/instance |

### 6.2 Database Scaling

| Phase | Strategy |
|:---|:---|
| MVP | Single PostgreSQL instance (shared schemas) |
| Growth | Read replicas for Profile and Feed queries |
| Scale | Separate PostgreSQL instances per service |
| Enterprise | PgBouncer connection pooling + Citus for horizontal sharding |

### 6.3 WebSocket Scaling

```
                   ┌─────── Load Balancer (sticky sessions) ──────┐
                   │                    │                          │
          ┌────────▼──┐       ┌────────▼──┐              ┌───────▼───┐
          │ Messaging │       │ Messaging │              │ Messaging │
          │ Instance 1│       │ Instance 2│              │ Instance N│
          └────┬──────┘       └────┬──────┘              └────┬──────┘
               │                   │                          │
               └───────────── Redis Pub/Sub ──────────────────┘
                            (fan-out adapter)
```

- Socket.IO with `@socket.io/redis-adapter` for cross-instance message relay.
- Sticky sessions at the load balancer (based on user ID hash) to minimize Redis pub/sub traffic.
- Connection draining on scale-down (graceful WebSocket migration).

---

## 7. CDN & Static Assets

| Asset Type | Storage | CDN |
|:---|:---|:---|
| User avatars | S3 | CloudFront / Cloud CDN |
| Post media (images, PDFs) | S3 | CloudFront / Cloud CDN |
| App assets (Flutter web) | S3 | CloudFront / Cloud CDN |

**Cache policy**: Immutable assets (uploaded files) cached indefinitely with unique file names (UUID-based). Dynamic assets (avatars) cached with 1-hour TTL and `Cache-Control: max-age=3600`.

---

## 8. Performance Benchmarks (Targets)

| Operation | Target (p95) | Measurement Point |
|:---|:---|:---|
| Login | < 500ms | Client → Gateway → Auth → Response |
| Load local feed (cached) | < 200ms | Gateway → Feed → Redis → Response |
| Load local feed (uncached) | < 2000ms | Gateway → Feed → PostgreSQL → Response |
| User search | < 1000ms | Gateway → Profile → PostgreSQL → Response |
| Send message (WebSocket) | < 300ms | Client → Messaging → Persist + Pub/Sub → Delivery |
| Send message (HTTP fallback) | < 1000ms | Client → Gateway → Messaging → Response |
| File upload (10MB) | < 5000ms | Client → S3 direct upload via presigned URL |

---

## 9. Disaster Recovery

| Component | RPO | RTO | Strategy |
|:---|:---|:---|:---|
| PostgreSQL | 1 hour | 4 hours | Automated point-in-time backups (daily full + WAL archiving) |
| Redis | Acceptable loss | 5 minutes | Redis persistence (RDB snapshots every 5 min) + rebuild from DB |
| S3 files | 0 (durability) | Immediate | S3 cross-region replication |
| Service code | 0 | 15 minutes | Container re-deployment from registry |

**Backup schedule:**
- PostgreSQL: Daily full backup at 03:00 UTC + continuous WAL archiving.
- Redis: RDB snapshot every 5 minutes (acceptable data loss for cache).
- S3: Built-in 11 9's durability.
