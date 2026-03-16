# InteraEdu — Data Architecture

**Version:** 2.0
**Date:** March 2026

---

## 1. Database Strategy

### 1.1 Shared Instance, Separate Schemas
In the MVP, all services share a single PostgreSQL 16 instance but use **separate schemas** to maintain logical ownership boundaries:

| Schema | Owner | Purpose |
|:---|:---|:---|
| `auth` | Auth Service | Credentials, tokens, OTP, institutions |
| `profile` | Profile Service | User profiles, skills, connections |
| `feed` | Feed Service | Posts, reactions, comments |
| `messaging` | Messaging Service | Chats, messages, read receipts |

Each service has exclusive read/write access to its own schema. Cross-schema queries are **forbidden** — services communicate via HTTP or events.

### 1.2 Multi-Tenant Filtering
Multi-tenancy is implemented via a `institution_id` column on relevant tables. PostgreSQL **Row-Level Security (RLS)** provides a database-level guardrail:

```sql
-- Example RLS policy for local-scoped feed queries
ALTER TABLE feed.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY local_feed_policy ON feed.posts
  FOR SELECT
  USING (
    scope = 'global'
    OR institution_id = current_setting('app.current_institution_id')::uuid
  );
```

The application sets `SET LOCAL app.current_institution_id = '<uuid>'` at the start of each transaction.

---

## 2. Schema Definitions

### 2.1 Auth Schema

```sql
-- Institutions (Tenants)
CREATE TABLE auth.institutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  domains TEXT[] NOT NULL,               -- Array of approved email domains
  is_verified BOOLEAN DEFAULT false,
  logo_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_institutions_domains ON auth.institutions USING GIN (domains);

-- User credentials
CREATE TABLE auth.user_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(320) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  institution_id UUID NOT NULL REFERENCES auth.institutions(id),
  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'suspended', 'deleted')),
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ               -- Soft delete
);

CREATE INDEX idx_user_credentials_email ON auth.user_credentials(email);
CREATE INDEX idx_user_credentials_institution ON auth.user_credentials(institution_id);
CREATE INDEX idx_user_credentials_status ON auth.user_credentials(status) WHERE status = 'active';

-- OTP codes
CREATE TABLE auth.otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(320) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,      -- bcrypt hash of OTP
  purpose VARCHAR(20) NOT NULL
    CHECK (purpose IN ('registration', 'login', 'password_reset')),
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  used_at TIMESTAMPTZ
);

CREATE INDEX idx_otp_email_purpose ON auth.otp_codes(email, purpose) WHERE used_at IS NULL;

-- Refresh tokens
CREATE TABLE auth.refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.user_credentials(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL UNIQUE,
  device_info JSONB,                    -- { platform, os, device_name }
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user ON auth.refresh_tokens(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_tokens_hash ON auth.refresh_tokens(token_hash);

-- LGPD consent records
CREATE TABLE auth.consent_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.user_credentials(id) ON DELETE CASCADE,
  consent_type VARCHAR(50) NOT NULL,    -- 'terms_of_service', 'privacy_policy'
  version VARCHAR(20) NOT NULL,         -- 'v2.1'
  accepted_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT
);

CREATE INDEX idx_consent_user ON auth.consent_records(user_id);

-- Auth audit log
CREATE TABLE auth.audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(50) NOT NULL,          -- 'login_success', 'login_failed', 'password_changed', etc.
  ip_address INET,
  user_agent TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_auth_audit_user ON auth.audit_log(user_id);
CREATE INDEX idx_auth_audit_action ON auth.audit_log(action);
CREATE INDEX idx_auth_audit_created ON auth.audit_log(created_at);
```

### 2.2 Profile Schema

```sql
-- User profiles
CREATE TABLE profile.users (
  id UUID PRIMARY KEY,                  -- Same UUID as auth.user_credentials.id
  institution_id UUID NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  bio TEXT,
  course VARCHAR(255),
  period INTEGER,                       -- Current semester/year
  privacy_level VARCHAR(20) DEFAULT 'local_only'
    CHECK (privacy_level IN ('public', 'local_only', 'private')),
  avatar_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_profile_users_institution ON profile.users(institution_id);
CREATE INDEX idx_profile_users_course ON profile.users(institution_id, course);
CREATE INDEX idx_profile_users_name_search ON profile.users USING GIN (
  to_tsvector('portuguese', full_name)
);

-- Skill taxonomy
CREATE TABLE profile.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  category VARCHAR(50) NOT NULL,        -- 'programming', 'design', 'science', 'language'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_skills_category ON profile.skills(category);
CREATE INDEX idx_skills_name_search ON profile.skills USING GIN (
  to_tsvector('simple', name)
);

-- User-skill association
CREATE TABLE profile.user_skills (
  user_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES profile.skills(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, skill_id)
);

CREATE INDEX idx_user_skills_skill ON profile.user_skills(skill_id);

-- External links
CREATE TABLE profile.user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  link_type VARCHAR(20) NOT NULL
    CHECK (link_type IN ('github', 'lattes', 'linkedin', 'website', 'other')),
  url VARCHAR(500) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_links_user ON profile.user_links(user_id);

-- Connections
CREATE TABLE profile.connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected')),
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE (requester_id, addressee_id)
);

CREATE INDEX idx_connections_requester ON profile.connections(requester_id, status);
CREATE INDEX idx_connections_addressee ON profile.connections(addressee_id, status);

-- Block list
CREATE TABLE profile.blocked_users (
  blocker_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  blocked_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- Profile audit log
CREATE TABLE profile.audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(50) NOT NULL,
  target_type VARCHAR(50),
  target_id UUID,
  changes JSONB,                        -- { field: { old, new } }
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profile_audit_user ON profile.audit_log(user_id);
CREATE INDEX idx_profile_audit_created ON profile.audit_log(created_at);
```

### 2.3 Feed Schema

```sql
-- Posts
CREATE TABLE feed.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL,
  institution_id UUID NOT NULL,
  content TEXT NOT NULL,
  scope VARCHAR(10) DEFAULT 'global'
    CHECK (scope IN ('local', 'global')),
  media_urls TEXT[],                    -- S3 URLs for attached files
  reaction_count INTEGER DEFAULT 0,     -- Denormalized counter
  comment_count INTEGER DEFAULT 0,      -- Denormalized counter
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Primary feed query indexes
CREATE INDEX idx_posts_local_feed ON feed.posts(institution_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_posts_global_feed ON feed.posts(created_at DESC)
  WHERE deleted_at IS NULL AND scope = 'global';
CREATE INDEX idx_posts_author ON feed.posts(author_id);

-- Full-text search on post content
CREATE INDEX idx_posts_content_search ON feed.posts USING GIN (
  to_tsvector('portuguese', content)
) WHERE deleted_at IS NULL;

-- Reactions
CREATE TABLE feed.reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES feed.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  reaction_type VARCHAR(20) NOT NULL
    CHECK (reaction_type IN ('like', 'insightful', 'support')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (post_id, user_id)             -- One reaction per user per post
);

CREATE INDEX idx_reactions_post ON feed.reactions(post_id);

-- Comments
CREATE TABLE feed.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES feed.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  parent_comment_id UUID REFERENCES feed.comments(id),  -- Single-level threading
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_comments_post ON feed.comments(post_id, created_at);
CREATE INDEX idx_comments_parent ON feed.comments(parent_comment_id);

-- Abuse reports
CREATE TABLE feed.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL,
  target_type VARCHAR(20) NOT NULL
    CHECK (target_type IN ('post', 'comment', 'user', 'message')),
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewed', 'action_taken', 'dismissed')),
  moderator_id UUID,
  moderator_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_reports_status ON feed.reports(status) WHERE status = 'pending';

-- Feed audit log
CREATE TABLE feed.audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(50) NOT NULL,
  target_type VARCHAR(50),
  target_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feed_audit_created ON feed.audit_log(created_at);
```

### 2.4 Messaging Schema

```sql
-- Chats
CREATE TABLE messaging.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_type VARCHAR(10) NOT NULL
    CHECK (chat_type IN ('direct', 'group')),
  name VARCHAR(255),                    -- NULL for direct chats
  description TEXT,
  topic_tags TEXT[],
  max_members INTEGER DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat members
CREATE TABLE messaging.chat_members (
  chat_id UUID NOT NULL REFERENCES messaging.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role VARCHAR(10) DEFAULT 'member'
    CHECK (role IN ('member', 'admin')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  PRIMARY KEY (chat_id, user_id)
);

CREATE INDEX idx_chat_members_user ON messaging.chat_members(user_id) WHERE left_at IS NULL;

-- Messages
CREATE TABLE messaging.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES messaging.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  content TEXT,
  file_url VARCHAR(500),
  file_name VARCHAR(255),
  file_size_bytes INTEGER,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_messages_chat_sent ON messaging.messages(chat_id, sent_at DESC);
CREATE INDEX idx_messages_sender ON messaging.messages(sender_id);

-- Read receipts
CREATE TABLE messaging.read_receipts (
  chat_id UUID NOT NULL REFERENCES messaging.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  last_read_message_id UUID REFERENCES messaging.messages(id),
  read_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

-- Messaging audit log
CREATE TABLE messaging.audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(50) NOT NULL,
  chat_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_msg_audit_created ON messaging.audit_log(created_at);
```

---

## 3. Rate Limiting Table

```sql
-- Shared rate limiting (used by API Gateway via Redis, persisted for analytics)
CREATE TABLE public.rate_limit_log (
  id BIGSERIAL PRIMARY KEY,
  identifier VARCHAR(255) NOT NULL,     -- IP address or user_id
  endpoint VARCHAR(255) NOT NULL,
  request_count INTEGER DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL,
  window_end TIMESTAMPTZ NOT NULL,
  blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_identifier ON public.rate_limit_log(identifier, endpoint, window_start);
```

> **Note:** Real-time rate limiting uses Redis sliding window counters. This table is for audit/analytics only.

---

## 4. Search Strategy

### Phase 1 (MVP): PostgreSQL Native
- **Full-text search**: `to_tsvector('portuguese', ...)` with GIN indexes on `profile.users.full_name`, `feed.posts.content`.
- **Skills search**: B-tree index on `profile.user_skills.skill_id` with join queries.
- **Filtered search**: Composite indexes on `(institution_id, course)`.

### Phase 2 (Scale): Elasticsearch Migration
When reaching >100K users:
- Deploy Elasticsearch cluster.
- Use Change Data Capture (CDC) via Debezium to sync PostgreSQL → Elasticsearch.
- Migrate search queries to Elasticsearch API.
- PostgreSQL remains the source of truth.

---

## 5. Data Lifecycle & Retention

| Data Type | Retention | Strategy |
|:---|:---|:---|
| Active user data | Indefinite | Normalize, index |
| Soft-deleted content | 90 days | `deleted_at` → purge job |
| Audit logs | 5 years | Partition by month, archive to cold storage |
| OTP codes | 10 minutes | Redis TTL + DB cleanup job |
| Refresh tokens (revoked) | 30 days | Cleanup job |
| Rate limit logs | 90 days | Cleanup job |
| Anonymized user data | Indefinite | Replaced with "Deleted User" |
