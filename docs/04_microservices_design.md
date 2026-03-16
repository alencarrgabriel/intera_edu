# InteraEdu — Microservices Design

**Version:** 2.0
**Date:** March 2026

---

## 1. Auth Service

### 1.1 Responsibilities
- Institutional email domain validation
- OTP generation, delivery, and verification
- User credential management (password hashing, storage)
- JWT access token and refresh token lifecycle
- Token revocation (logout, password change)
- Institution domain registry management

### 1.2 Internal Modules

```
auth-service/
├── auth/           # Login, token issuance, token refresh
├── registration/   # Registration flow (init → OTP → complete)
├── otp/            # OTP generation, storage (Redis), verification
├── domain-validation/  # Email domain whitelist check
├── token/          # JWT signing, refresh token rotation, blacklist
├── institution/    # CRUD for institutional domains
└── database/       # TypeORM entities, migrations
```

### 1.3 Database Ownership

**Schema:** `auth`

| Table | Purpose |
|:---|:---|
| `auth.institutions` | IES registry with approved email domains |
| `auth.users_credentials` | User ID, email, password hash, status |
| `auth.refresh_tokens` | Active refresh tokens (user_id, token_hash, expires_at, device_info) |
| `auth.otp_codes` | Pending OTPs (email, code_hash, expires_at, attempts) |
| `auth.consent_records` | LGPD consent versions accepted by each user |
| `auth.audit_log` | Authentication events (login success/failure, password changes) |

### 1.4 External Dependencies
- **Redis**: OTP storage (TTL-based), token blacklist, rate limit counters
- **Email Provider**: SMTP / SendGrid / AWS SES for OTP delivery

### 1.5 API Contracts

| Method | Endpoint | Purpose |
|:---|:---|:---|
| `POST` | `/auth/register` | Start registration (validate domain, send OTP) |
| `POST` | `/auth/verify-otp` | Verify OTP code |
| `POST` | `/auth/complete-registration` | Set password, accept terms, create account |
| `POST` | `/auth/login` | Email + password login |
| `POST` | `/auth/refresh` | Rotate refresh token, issue new access token |
| `POST` | `/auth/logout` | Revoke refresh token |
| `POST` | `/auth/forgot-password` | Initiate password reset via OTP |
| `POST` | `/auth/reset-password` | Complete password reset |

### 1.6 Events Emitted

| Event | Payload | When |
|:---|:---|:---|
| `user.registered` | `{ userId, email, institutionId }` | After successful registration completion |
| `user.deleted` | `{ userId }` | After account deletion request confirmed |
| `user.password_changed` | `{ userId }` | After password change (for session invalidation) |

### 1.7 Events Consumed

| Event | From | Action |
|:---|:---|:---|
| — | — | Auth Service is primarily a producer, not consumer |

---

## 2. Profile Service

### 2.1 Responsibilities
- User profile CRUD (name, course, semester, links)
- Skill management (taxonomy, user-skill associations)
- Connection management (request, accept, reject, block)
- Privacy level enforcement
- User search and discovery
- Data export (LGPD)

### 2.2 Internal Modules

```
profile-service/
├── profile/        # Profile CRUD, privacy level management
├── skills/         # Skill taxonomy, user-skill junction
├── connections/    # Connection requests, acceptance, blocking
├── search/         # User search with filters (skills, institution, course)
├── data-export/    # LGPD data export generation
└── database/       # TypeORM entities, migrations
```

### 2.3 Database Ownership

**Schema:** `profile`

| Table | Purpose |
|:---|:---|
| `profile.users` | User profiles (name, institution_id, course, period, privacy_level, bio) |
| `profile.skills` | Skill taxonomy (id, name, category, slug) |
| `profile.user_skills` | Junction table (user_id, skill_id) |
| `profile.user_links` | External links (user_id, type [github/lattes/linkedin], url) |
| `profile.connections` | Connection requests (user_a_id, user_b_id, status, requested_at, responded_at) |
| `profile.blocked_users` | Block list (blocker_id, blocked_id, blocked_at) |
| `profile.audit_log` | Profile change events |

### 2.4 External Dependencies
- **Auth Service**: Token validation (via shared JWT guard)
- **Redis**: Profile cache, search result cache

### 2.5 API Contracts

| Method | Endpoint | Purpose |
|:---|:---|:---|
| `GET` | `/users/me` | Get own profile |
| `PATCH` | `/users/me` | Update own profile |
| `DELETE` | `/users/me` | Request account deletion (LGPD) |
| `GET` | `/users/me/data-export` | Request data export (LGPD) |
| `GET` | `/users/:id` | View another user's profile (privacy-aware) |
| `GET` | `/users/search` | Search users (filters: skill, institution, course) |
| `POST` | `/connections` | Send connection request |
| `PATCH` | `/connections/:id` | Accept or reject connection |
| `DELETE` | `/connections/:id` | Remove connection |
| `POST` | `/users/:id/block` | Block a user |
| `DELETE` | `/users/:id/block` | Unblock a user |
| `GET` | `/skills` | List skill taxonomy |
| `GET` | `/skills/search` | Search skills by name |

### 2.6 Events Emitted

| Event | Payload | When |
|:---|:---|:---|
| `profile.updated` | `{ userId, fields[] }` | Profile fields changed |
| `connection.requested` | `{ fromUserId, toUserId, connectionId }` | Connection request sent |
| `connection.accepted` | `{ connectionId, userAId, userBId }` | Connection accepted |
| `connection.removed` | `{ connectionId, userAId, userBId }` | Connection removed |
| `user.blocked` | `{ blockerId, blockedId }` | User blocked |

### 2.7 Events Consumed

| Event | From | Action |
|:---|:---|:---|
| `user.registered` | Auth Service | Create initial profile record |
| `user.deleted` | Auth Service | Anonymize profile, remove connections |

---

## 3. Feed Service

### 3.1 Responsibilities
- Post CRUD (create, read, soft-delete)
- Local feed generation (institution-scoped)
- Global feed generation with Force Exploration algorithm
- Feed caching and invalidation
- Reactions and comments management
- Post reporting

### 3.2 Internal Modules

```
feed-service/
├── posts/          # Post CRUD, validation, file attachment references
├── feed/           # Feed generation (local, global, Force Exploration)
├── reactions/      # Post reactions (like, insightful, support)
├── comments/       # Post comments (single-level threading)
├── reports/        # Post/content abuse reports
├── cache/          # Redis feed cache management
└── database/       # TypeORM entities, migrations
```

### 3.3 Database Ownership

**Schema:** `feed`

| Table | Purpose |
|:---|:---|
| `feed.posts` | Posts (author_id, institution_id, content, scope, media_urls, created_at, deleted_at) |
| `feed.reactions` | Reactions (post_id, user_id, type, created_at) |
| `feed.comments` | Comments (post_id, user_id, parent_comment_id, content, created_at, deleted_at) |
| `feed.reports` | Abuse reports (reporter_id, target_type, target_id, reason, status, created_at) |
| `feed.audit_log` | Feed events |

### 3.4 External Dependencies
- **Profile Service**: Author profile enrichment (batch lookup by user IDs)
- **Redis**: Feed cache (keyed by institution_id + cursor), post count cache
- **Object Storage**: Media file URLs

### 3.5 API Contracts

| Method | Endpoint | Purpose |
|:---|:---|:---|
| `GET` | `/posts` | Get feed (query: scope=local/global, cursor, limit) |
| `POST` | `/posts` | Create post |
| `GET` | `/posts/:id` | Get single post |
| `DELETE` | `/posts/:id` | Soft-delete own post |
| `POST` | `/posts/:id/reactions` | Add reaction |
| `DELETE` | `/posts/:id/reactions` | Remove reaction |
| `GET` | `/posts/:id/comments` | List comments (paginated) |
| `POST` | `/posts/:id/comments` | Add comment |
| `DELETE` | `/comments/:id` | Soft-delete own comment |
| `POST` | `/reports` | Report content |

### 3.6 Events Emitted

| Event | Payload | When |
|:---|:---|:---|
| `post.created` | `{ postId, authorId, institutionId, scope }` | New post created |
| `post.deleted` | `{ postId, institutionId }` | Post soft-deleted |
| `reaction.added` | `{ postId, userId, type }` | Reaction added to post |
| `comment.added` | `{ postId, commentId, userId }` | Comment added to post |

### 3.7 Events Consumed

| Event | From | Action |
|:---|:---|:---|
| `user.deleted` | Auth Service | Anonymize all posts by that user |
| `profile.updated` | Profile Service | Invalidate cached author data in feed |

---

## 4. Messaging Service

### 4.1 Responsibilities
- 1:1 chat management
- Study group management (create, join, leave, admin)
- Real-time message delivery via WebSocket
- Message persistence and history
- File sharing in chats
- Typing indicators
- Read receipts

### 4.2 Internal Modules

```
messaging-service/
├── chats/          # Chat CRUD (1:1 and group)
├── messages/       # Message persistence, history retrieval
├── groups/         # Study group management (create, join, leave, admin)
├── websocket/      # Socket.IO gateway, connection management, event handlers
├── files/          # File upload handling (S3 presigned URLs)
└── database/       # TypeORM entities, migrations
```

### 4.3 Database Ownership

**Schema:** `messaging`

| Table | Purpose |
|:---|:---|
| `messaging.chats` | Chat rooms (id, type [direct/group], name, created_at) |
| `messaging.chat_members` | Chat membership (chat_id, user_id, role [member/admin], joined_at) |
| `messaging.messages` | Messages (chat_id, sender_id, content, file_url, sent_at, edited_at) |
| `messaging.read_receipts` | Read markers (chat_id, user_id, last_read_message_id, read_at) |
| `messaging.audit_log` | Messaging events |

### 4.4 External Dependencies
- **Profile Service**: User lookup for display names/avatars
- **Redis**: Pub/Sub for WebSocket fan-out, online status tracking
- **Object Storage**: File uploads via presigned URLs
- **FCM**: Push notifications for offline users

### 4.5 API Contracts (HTTP)

| Method | Endpoint | Purpose |
|:---|:---|:---|
| `GET` | `/chats` | List user's chats (paginated) |
| `POST` | `/chats` | Create new chat (1:1 or group) |
| `GET` | `/chats/:id` | Get chat details |
| `PATCH` | `/chats/:id` | Update group settings (name, description) |
| `DELETE` | `/chats/:id` | Leave/delete chat |
| `POST` | `/chats/:id/members` | Add member to group |
| `DELETE` | `/chats/:id/members/:userId` | Remove member from group |
| `GET` | `/chats/:id/messages` | Get message history (cursor-based) |
| `POST` | `/chats/:id/messages` | Send message (HTTP fallback) |
| `POST` | `/upload/presign` | Get presigned URL for file upload |

### 4.6 API Contracts (WebSocket)

| Event | Direction | Payload |
|:---|:---|:---|
| `message:send` | Client → Server | `{ chatId, content, fileUrl? }` |
| `message:new` | Server → Client | `{ messageId, chatId, senderId, content, sentAt }` |
| `message:read` | Client → Server | `{ chatId, lastReadMessageId }` |
| `message:read_update` | Server → Client | `{ chatId, userId, lastReadMessageId }` |
| `typing:start` | Client → Server | `{ chatId }` |
| `typing:stop` | Client → Server | `{ chatId }` |
| `typing:indicator` | Server → Client | `{ chatId, userId, isTyping }` |
| `user:online` | Server → Client | `{ userId, isOnline }` |

### 4.7 Events Emitted

| Event | Payload | When |
|:---|:---|:---|
| `message.sent` | `{ chatId, messageId, senderId, recipientIds[] }` | New message persisted |
| `group.created` | `{ chatId, creatorId, memberIds[] }` | Study group created |

### 4.8 Events Consumed

| Event | From | Action |
|:---|:---|:---|
| `connection.accepted` | Profile Service | Optionally enable DM (no auto-creation, but allow initiation) |
| `connection.removed` | Profile Service | Mark existing DM as archived (not deleted) |
| `user.deleted` | Auth Service | Anonymize sender in all messages, remove from group memberships |
| `user.blocked` | Profile Service | Remove blocked user from shared chats, prevent messaging |
