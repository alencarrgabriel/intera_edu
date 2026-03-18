# InteraEdu — Arquitetura de Dados

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Estratégia de Banco de Dados

### 1.1 Instância Compartilhada, Schemas Separados
No MVP, todos os serviços compartilham uma única instância PostgreSQL 16 mas usam **esquemas (schemas) separados** para manter os limites lógicos de propriedade:

| Schema | Responsável | Propósito |
|:---|:---|:---|
| `auth` | Serviço Auth | Credenciais, tokens, OTP, instituições |
| `profile` | Serviço Profile | Perfis de usuário, habilidades, conexões |
| `feed` | Serviço Feed | Posts, reações, comentários |
| `messaging` | Serviço Messaging | Chats, mensagens, confirmações de leitura |

Cada serviço tem acesso exclusivo de leitura/escrita ao seu próprio esquema. Consultas cruzadas entre esquemas são **proibidas** — os serviços se comunicam via HTTP ou eventos.

### 1.2 Filtragem Multi-Inquilino (Multi-Tenant)
O design multi-inquilino é implementado via coluna `institution_id` nas tabelas relevantes. **A Segurança em Nível de Linha (RLS)** do PostgreSQL fornece uma proteção nativa no nível do banco:

```sql
-- Exemplo de política RLS para consultas de feed com escopo local
ALTER TABLE feed.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY local_feed_policy ON feed.posts
  FOR SELECT
  USING (
    scope = 'global'
    OR institution_id = current_setting('app.current_institution_id')::uuid
  );
```

A aplicação define `SET LOCAL app.current_institution_id = '<uuid>'` no início de cada transação.

---

## 2. Definições dos Schemas

### 2.1 Schema Auth

```sql
-- Instituições Educacionais
CREATE TABLE auth.institutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  domains TEXT[] NOT NULL,               -- Array de domínios de e-mail aprovados
  is_verified BOOLEAN DEFAULT false,
  logo_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_institutions_domains ON auth.institutions USING GIN (domains);

-- Credenciais de usuário
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
  deleted_at TIMESTAMPTZ               -- Exclusão lógica (Soft delete)
);

CREATE INDEX idx_user_credentials_email ON auth.user_credentials(email);
CREATE INDEX idx_user_credentials_institution ON auth.user_credentials(institution_id);
CREATE INDEX idx_user_credentials_status ON auth.user_credentials(status) WHERE status = 'active';

-- Códigos OTP
CREATE TABLE auth.otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(320) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,      -- Hash bcrypt do OTP
  purpose VARCHAR(20) NOT NULL
    CHECK (purpose IN ('registration', 'login', 'password_reset')),
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  used_at TIMESTAMPTZ
);

CREATE INDEX idx_otp_email_purpose ON auth.otp_codes(email, purpose) WHERE used_at IS NULL;

-- Tokens de Atualização (Refresh Tokens)
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

-- Registros de consentimento LGPD
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

-- Log de auditoria de autenticação
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

### 2.2 Schema Profile

```sql
-- Perfis de usuário
CREATE TABLE profile.users (
  id UUID PRIMARY KEY,                  -- Mesmo UUID de auth.user_credentials.id
  institution_id UUID NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  bio TEXT,
  course VARCHAR(255),
  period INTEGER,                       -- Semestre/período atual
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

-- Taxonomia de habilidades
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

-- Associação usuário-habilidade
CREATE TABLE profile.user_skills (
  user_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES profile.skills(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, skill_id)
);

CREATE INDEX idx_user_skills_skill ON profile.user_skills(skill_id);

-- Links externos
CREATE TABLE profile.user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  link_type VARCHAR(20) NOT NULL
    CHECK (link_type IN ('github', 'lattes', 'linkedin', 'website', 'other')),
  url VARCHAR(500) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_links_user ON profile.user_links(user_id);

-- Conexões
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

-- Lista de bloqueio
CREATE TABLE profile.blocked_users (
  blocker_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profile.users(id) ON DELETE CASCADE,
  blocked_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- Log de auditoria de perfil
CREATE TABLE profile.audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action VARCHAR(50) NOT NULL,
  target_type VARCHAR(50),
  target_id UUID,
  changes JSONB,                        -- { campo: { antigo, novo } }
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profile_audit_user ON profile.audit_log(user_id);
CREATE INDEX idx_profile_audit_created ON profile.audit_log(created_at);
```

### 2.3 Schema Feed

```sql
-- Publicações (Posts)
CREATE TABLE feed.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL,
  institution_id UUID NOT NULL,
  content TEXT NOT NULL,
  scope VARCHAR(10) DEFAULT 'global'
    CHECK (scope IN ('local', 'global')),
  media_urls TEXT[],                    -- URLs S3 para arquivos anexados
  reaction_count INTEGER DEFAULT 0,     -- Contador desnormalizado
  comment_count INTEGER DEFAULT 0,      -- Contador desnormalizado
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Índices primários de consulta do feed
CREATE INDEX idx_posts_local_feed ON feed.posts(institution_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_posts_global_feed ON feed.posts(created_at DESC)
  WHERE deleted_at IS NULL AND scope = 'global';
CREATE INDEX idx_posts_author ON feed.posts(author_id);

-- Busca de texto completo no conteúdo dos posts
CREATE INDEX idx_posts_content_search ON feed.posts USING GIN (
  to_tsvector('portuguese', content)
) WHERE deleted_at IS NULL;

-- Reações
CREATE TABLE feed.reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES feed.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  reaction_type VARCHAR(20) NOT NULL
    CHECK (reaction_type IN ('like', 'insightful', 'support')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (post_id, user_id)             -- Uma reação por usuário por post
);

CREATE INDEX idx_reactions_post ON feed.reactions(post_id);

-- Comentários
CREATE TABLE feed.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES feed.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  parent_comment_id UUID REFERENCES feed.comments(id),  -- Encadeamento com apenas 1 nível
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_comments_post ON feed.comments(post_id, created_at);
CREATE INDEX idx_comments_parent ON feed.comments(parent_comment_id);

-- Denúncias de abuso
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

-- Log de auditoria do feed
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

### 2.4 Schema Messaging

```sql
-- Turmas e Conversas Privadas (Chats)
CREATE TABLE messaging.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_type VARCHAR(10) NOT NULL
    CHECK (chat_type IN ('direct', 'group')),
  name VARCHAR(255),                    -- Nulo para conversas diretas
  description TEXT,
  topic_tags TEXT[],
  max_members INTEGER DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Membros do chat
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

-- Mensagens Trocdas
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

-- Recibos e Confirmações de leitura (Visto de última mensagem)
CREATE TABLE messaging.read_receipts (
  chat_id UUID NOT NULL REFERENCES messaging.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  last_read_message_id UUID REFERENCES messaging.messages(id),
  read_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

-- Log de auditoria de mensagens
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

## 3. Tabela de Limitação de Requisição (Rate Limiting)

```sql
-- Log de Limite de Taxa compartilhado (usado pelo API Gateway via Redis, gravado para analytics)
CREATE TABLE public.rate_limit_log (
  id BIGSERIAL PRIMARY KEY,
  identifier VARCHAR(255) NOT NULL,     -- Endereço IP ou ID do usuário
  endpoint VARCHAR(255) NOT NULL,
  request_count INTEGER DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL,
  window_end TIMESTAMPTZ NOT NULL,
  blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_identifier ON public.rate_limit_log(identifier, endpoint, window_start);
```

> **Aviso:** O bloqueio em tempo real usa contadores de janela deslizante no Redis. O PostgreSQL anota isso friamente para auditoria depois (Analytics).

---

## 4. Estratégia de Busca e Pesquisa

### Fase 1 (MVP): PostgreSQL Nativo
- **Busca via texto completo**: `to_tsvector('portuguese', ...)` somada com índices GIN pesados no campo de nomes (`profile.users.full_name`) e dos textos redigidos em posts (`feed.posts.content`).
- **Peneira por habilidades formadas**: Índice pesado B-tree no elo `profile.user_skills.skill_id` unindo as views apropriadas.
- **Filtro combinatório avançado**: Índices paralelos complexos (`institution_id, course`).

### Fase 2 (Escala Global): Mudança Provisória para Elasticsearch
No cenário de bater 100K pessoas fixas:
- Levanta implantação Elasticsearch nativa.
- Usa Change Data Capture (CDC) puxando a alavanca Debezium para forçar cópia fria do PostgreSQL → Elasticsearch.
- Transfere as chamadas HTTP cruas das buscas complexas para a API do Elastic.
- PostgreSQL enraíza intocável como a principal e única fonte de verdade final.

---

## 5. Ciclo de Vida e Retenção de Dados

| Tipo de Base Lógica | Sobrevivência | Plano de Voo |
|:---|:---|:---|
| Conta base viva | De AdEternum | Deixar intocável |
| Dado varrido por Soft Delete | Sobrevida de 90 dias | O ponteiro `deleted_at` engatilha e apaga do BD pra sempre (Pós Job Limpador) |
| Entradas Frias de Auditoria | 5 anos longos | Mês a Mês os lotes são transferidos e jogados para um disco SSD parado de Cold Storage |
| Códigos Descartáveis OTP | 10 minutinhos | Tempo limite no Redis espirra; Banco varre o vazio de hora em hora |
| Tokens Defesos e Revogados | Menos de 1 Mês | Entra a vassoura mensal para varrer Tokens marcados como inválidos |
| Lixos de Taxa de Requisição Diária | Sobrevida Fria de 90 dias | Job Noturno varre após Data Máxima |
| Perfis Apagados pela Pessoa (LGPD) | AdEternum Vazio | As planilhas preservam o escarço sem ligar ao nome. Muda o flag pro vulgo textual "Usuário Excluído" |
