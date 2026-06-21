# InteraEdu — Resumo de Implementação

> Documento consolidado de tudo o que foi construído nas últimas semanas de desenvolvimento do MVP do InteraEdu.

**Período:** Maio–Junho 2026
**Cobertura do SRS:** 45 de 50 requisitos funcionais (90%)
**Stack:** NestJS + PostgreSQL + Redis + MinIO + Flutter Web

---

## 1. Visão geral

O InteraEdu é uma rede social acadêmica restrita a estudantes e pesquisadores verificados por e-mail institucional. A tese central — "quebrar silos entre universidades" — é sustentada pelo algoritmo de **Exploração Forçada** (RN-03), que injeta ≥20% de conteúdo de outras IES no feed global de qualquer usuário.

O sistema é multi-tenant (uma IES = um tenant) e foi desenhado sob a LGPD desde a fundação — consentimento versionado, exportação de dados, exclusão com anonimização, trilha de auditoria.

### Arquitetura

```
Flutter Web (localhost:8090)
        │
        ▼ HTTPS / WSS
API Gateway (3000) — rate-limit + multipart proxy + métricas Prometheus
        │
   ┌────┼─────────────────────────────┐
   ▼    ▼          ▼          ▼          ▼
auth(3001) profile(3002) feed(3003) messaging(3004)
   │       │           │          │
   └───────┴───────────┴──────────┘
              │
         PostgreSQL 16  +  Redis 7  +  MinIO (S3)
              │
         Prometheus + Grafana (observabilidade)
```

Cada serviço tem seu próprio schema PostgreSQL (`auth`, `profile`, `feed`, `messaging`, `audit`) e não faz joins cross-schema. Comunicação assíncrona via Redis Pub/Sub no canal `interaedu.events`.

---

## 2. Funcionalidades implementadas

### 2.1 Autenticação e onboarding

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-01** | Registro com e-mail institucional | Backend valida domínio contra `auth.institutions` (UFMG, USP, UNICAMP, UNIFESP, CEUB, UnB) |
| **RF-02** | Verificação OTP | 6 dígitos, TTL 10min, max 5 tentativas + cooldown 15min, max 3 envios/hora |
| **RF-03** | Senha forte (8+ chars, maiúscula/minúscula/número/especial) | `Validators.password` no Flutter + bcrypt(12) no backend |
| **RF-04** | JWT com rotação | Access 15min em memória; refresh 7d hashado em `auth.refresh_tokens`; rotação a cada uso; replay → revoga família inteira |
| **RF-05** | Logout | Invalida refresh token específico |
| **RF-06** | Esqueci minha senha | OTP via `/auth/forgot-password` → `/auth/reset-password`; revoga sessões ativas; tela `ForgotPasswordScreen` |
| **B-03** | Login com Google OAuth | Endpoint `/auth/google` valida ID token via `google-auth-library`. Falta apenas o operador configurar `GOOGLE_CLIENT_ID` no `web/index.html` + docker-compose |

### 2.2 Perfil e descoberta

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-07/08** | Criar / editar perfil | Nome, curso, período, bio, skills (taxonomia curada), links externos |
| **RF-09** | Privacidade em 3 níveis | `public` / `local_only` / `private` controlam visibilidade entre IES e via conexão |
| **RF-10** | Visualizar outro perfil | Máscara automática quando viewer é de outra IES |
| **RF-11** | Taxonomia de skills | `profile.skills` populada com Python, ML, React, Data Analysis, UI/UX |
| **RF-12** | Busca interuniversitária | `/users/search?q&institution&course&skill_id` (skill filtrado no cliente) com 3 filtros funcionais por bottom sheet |
| **RF-15** | Bloquear usuário | Tabela `profile.user_blocks` + endpoints `/users/me/blocks/:id` + menu 3-dots no perfil |
| **Avatar (B-02)** | Upload de foto | Multipart pelo gateway → MinIO; bucket `interaedu/avatars/{uid}/{uuid}.{ext}`; máx 5MB |

### 2.3 Conexões

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-13** | Solicitar / aceitar / rejeitar conexão | Tabela `profile.connections` com estado `pending/accepted/rejected` |
| **RF-14** | Listar conexões e pendências | Endpoint enriquecido retorna `other_user` com nome/avatar/curso/instituição em batch — sem N+1 |
| Tela | **ConnectionsScreen** | Tabs "Pendentes (N)" + "Conectados" com cards Recusar/Aceitar gradiente |
| Tela | **Botão "Mensagem"** | No perfil de outro usuário cria chat direto e abre a sala |

### 2.4 Feed e conteúdo

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-16** | Criar publicação com texto + arquivo | Multipart em `/posts` faz upload pro MinIO em `posts/{uid}/{uuid}.{ext}`; tela `CreatePostScreen` com botão "Anexar" (PDF/JPG/PNG/WebP ≤10MB) |
| **RF-17** | Feed local | `GET /posts?scope=local` filtra por `institution_id` do viewer |
| **RF-18** | Feed global | `GET /posts?scope=global` com Exploração Forçada |
| **RF-19** | Toggle Local/Global | Segmented control no padrão Stitch |
| **RF-20** | Excluir publicação (soft delete) | `deleted_at` setado; mantido 90 dias para auditoria |
| **RF-21** | Reações (Curtir / Perspicaz / Apoio) | Tap = curtir, long-press abre `_ReactionPicker` com 3 opções; sem dislikes |
| **RF-22** | Comentários com replies (1 nível) | CommentsSheet agrupa por `parent_comment_id`, indenta replies, botão "Responder" preenche `_replyTo` |
| **RN-03** | Exploração Forçada ≥20% | `getGlobalFeed` separa 80% local + 20% externo, merge cronológico |
| **RN-04** | Sem ranking competitivo | Nenhum elemento de UI mostra notas, CRA ou contadores de "seguidores" |

### 2.5 Mensagens e colaboração

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-23** | Chat 1:1 em tempo real | WebSocket em Socket.IO, namespace `/ws`, autenticação via JWT no handshake |
| **RF-24** | Grupos de estudo (≤50) | `chat.type='group'` + `chat_members`; tela `CreateGroupScreen` lista conexões aceitas |
| **RF-25** | Mensagens em grupo | Mesma UI do 1:1, backend valida participação |
| **RF-26** | Histórico paginado por cursor | `GET /chats/:id/messages?cursor=` |
| **RF-27** | Arquivos em chat | Multipart em `/chats/:id/messages` com `file` faz upload pro MinIO em `chats/{chatId}/{uuid}.{ext}`; renderiza imagem inline ou chip PDF |
| **RF-28** | Indicador de digitação | Eventos `typing:start` / `typing:stop` via WebSocket; timeout local 3s |
| Conexão | Reconexão automática | `SocketService` reconnect via `AuthNotifier` após login/refresh |

### 2.6 LGPD e privacidade

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-29** | Consentimento versionado | `terms_version` + `privacy_version` gravados em `auth.consent_records` no complete-registration |
| **RF-30** | Exportação de dados em 48h | `GET /users/me/data-export` retorna JSON inline com profile + skills + connections + posts + comments + messages |
| **RF-31** | Exclusão com anonimização em 30d | `DELETE /users/me` marca soft delete + limpa connections + publica `user.deletion_requested`; subscriber anonimiza nome/avatar/bio |
| **RF-32** | Revogar consentimento | `POST /auth/revoke-consent` marca `revoked_at` em todos os consents + publica evento + dispara exclusão |
| **RF-33** | Trilha de auditoria 5 anos | Schema `audit.audit_logs`; interceptor global em `@interaedu/shared` loga POST/PATCH/PUT/DELETE com user/method/path/status/IP/body (senhas redacted) |
| **RN-09** | Re-consentimento ao mudar termos | `CURRENT_TERMS_VERSION` + login retorna `requires_consent_update:true` se versão obsoleta; `POST /auth/accept-terms` registra novo aceite |
| **RN-10** | Deleção em cascata | Evento `user.deletion_requested` publicado no Redis; subscriber em profile-service anonimiza perfil |
| Tela | **SettingsScreen** | 3 ações LGPD (exportar / revogar consentimento / excluir conta) acessível pela engrenagem do perfil |

### 2.7 Notificações

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-35** | Central in-app | Tabela `messaging.notifications` + endpoints `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`; tela acessível pelo sino |
| **RF-34** | Push notifications via Firebase FCM | ⏳ Mobile-only, fora de escopo do MVP web |
| **RF-36** | Configurar tipos de push | ⏳ Depende de RF-34 |

### 2.8 Administração e moderação

| ID | Recurso | Detalhes |
|---|---|---|
| **RF-37** | Cadastro de novas IES | `POST /institutions` (role admin); cria nome + slug + domínios + invalida cache Redis |
| **RF-38** | Gestão de domínios | `PATCH /institutions/:id/domains` com `{add: [], remove: []}` |
| **RF-39** | Fila de moderação | Tabela `feed.reports`; `GET /reports` lista abertas, `PATCH /reports/:id` resolve/descarta |
| **RF-40** | Reportar conteúdo | Botão "Denunciar" no menu 3-dots do PostCard e no perfil de outro usuário |
| Tela | **AdminScreen** | Rota `/admin` com 2 tabs (Instituições + Denúncias) — sem botão de navegação por design (acesso só por URL direta) |

### 2.9 Não-funcionais já implementados

| ID | Item | Como |
|---|---|---|
| **RNF-01** | Microsserviços | 5 serviços NestJS independentes (gateway, auth, profile, feed, messaging) |
| **RNF-02** | Feed <2s P95 | Cache Redis + paginação por cursor; instrumentado via Prometheus |
| **RNF-03** | Chat <500ms P95 | WebSocket direto; Socket.IO sobre Redis adapter |
| **RNF-11** | Sem ranking competitivo | Política de UI; nenhum componente mostra notas/CRA/seguidores |
| **RNF-13** | Logs estruturados | NestJS Logger padrão em todos os serviços (próximo: Pino para JSON) |
| **RNF-14** | pt-BR por padrão | Todas as strings em português brasileiro |
| **Rate limit** | 600 req/min default + 60 req/min em `/auth/*` | `PathAwareThrottlerGuard` no gateway; bucket por IP, retorno `TOO_MANY_REQUESTS` no formato canônico |
| **Multipart proxy** | Gateway encaminha multipart em streaming | Middleware Express `createMultipartProxy` antes do roteador NestJS, sem materializar body |
| **Observabilidade** | Prometheus + Grafana | Métricas HTTP do gateway (`/metrics`), dashboard "Saúde do Gateway" |

---

## 3. Stack tecnológica

| Camada | Tecnologia | Por quê |
|---|---|---|
| **Cliente** | Flutter 3.11 (Web) | Multiplataforma com SPA gerada por DDC |
| **Gateway** | NestJS 10 + axios + multipart-proxy custom | Rate limit + roteamento + métricas |
| **Microsserviços** | NestJS 10 + TypeORM 0.3 | Modular, fácil de subir/derrubar |
| **Banco** | PostgreSQL 16 | Schemas separados por serviço |
| **Cache / Pub-Sub** | Redis 7 | OTP storage, cache de feed, eventos |
| **Object storage** | MinIO (S3-compatível) | Avatares, anexos em chat, mídia em posts |
| **WebSocket** | Socket.IO 4 + redis-adapter | Chat real-time |
| **Auth** | JWT (HS256) + bcrypt(12) | Padrão de mercado |
| **OAuth** | google-auth-library | Validação de ID token |
| **Observabilidade** | Prometheus + Grafana | Dashboard de saúde do gateway |
| **Infra local** | Docker Compose | 10 containers em uma rede |

---

## 4. Como rodar

### Pré-requisitos
- Docker Desktop ≥ 24
- Flutter SDK ≥ 3.11
- Node.js 20 (apenas se for rodar `npm install --package-lock-only` para mudar deps)
- Python 3 (apenas para o seed bcrypt e scripts internos)

### Backend
```
cd backend
docker compose up -d --build
```

10 containers sobem: postgres, redis, minio, prometheus, grafana, gateway, auth-service, profile-service, feed-service, messaging-service.

### Seed de demonstração
```
cat backend/scripts/seed-demo.sql | docker exec -i interaedu-postgres psql -U interaedu -d interaedu
```

Popula 7 usuários (joao, maria, ana, pedro, julia, carla, lucas) com perfis completos + 5 conexões aceitas + 2 pendentes + 9 posts.

### Frontend
```
flutter pub get
flutter run -d web-server \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=WS_BASE_URL=http://localhost:3004 \
  --web-port=8090 --web-hostname=localhost
```

Acesse [http://localhost:8090](http://localhost:8090).

### Contas demo

| Email | Senha |
|---|---|
| `joao@ufmg.br` | (senha pessoal escolhida no cadastro) |
| `maria@usp.br` | `Senha@123` |
| `ana@aluno.ufmg.br`, `pedro@aluno.ufmg.br`, `julia@ufmg.br`, `carla@usp.br`, `lucas@alumni.usp.br` | `Demo@1234` |

---

## 5. URLs auxiliares

| Recurso | URL |
|---|---|
| App Flutter | http://localhost:8090 |
| Gateway (API) | http://localhost:3000/api/v1 |
| Gateway métricas | http://localhost:3000/metrics |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3030 (`admin / admin` ou anônimo) |
| Dashboard Gateway | http://localhost:3030/d/interaedu-gateway |
| MinIO Console | http://localhost:9001 (`minioadmin / minioadmin`) |
| Postgres | `localhost:5432` (`interaedu / interaedu_dev_password`) |
| Redis | `localhost:6379` |

---

## 6. Mapa de rotas Flutter

```
/welcome              splash com CTA "Começar" + "Já tenho conta"
/register             passo 1 (e-mail) → OTP
/otp                  passo 2 (código)
/profile-setup        passo 3 (nome + senha + skills + consent)
/login                login
/forgot-password      RF-06 recuperação de senha
/                     MainScreen com BottomNav (Início, Explorar, Conexões, Mensagens, Perfil)
/create-post          cria post (texto + anexo opcional)
/edit-profile         edita perfil
/connections          inbox de conexões com tabs Pendentes / Conectados
/user/:userId         perfil de outro usuário
/chat/:chatId         sala de conversa 1:1 ou grupo
/create-group         RF-24 nova sala em grupo
/notifications        RF-35 central in-app
/settings             RF-30/31/32 ações LGPD + logout
/admin                RF-37/38/39 cadastro de IES + moderação
```

---

## 7. Endpoints REST principais

### Autenticação
```
POST /api/v1/auth/register              { email }
POST /api/v1/auth/verify-otp            { email, code }
POST /api/v1/auth/complete-registration { temporary_token, password, full_name, ..., consent }
POST /api/v1/auth/login                 { email, password }  →  { tokens, requires_consent_update }
POST /api/v1/auth/refresh               { refresh_token }
POST /api/v1/auth/logout                { refresh_token }
POST /api/v1/auth/google                { id_token }
POST /api/v1/auth/forgot-password       { email }
POST /api/v1/auth/reset-password        { email, code, new_password }
POST /api/v1/auth/accept-terms          { user_id }                    # RN-09
POST /api/v1/auth/revoke-consent        { user_id }                    # RF-32
```

### Perfil / Conexões / Bloqueio / LGPD
```
GET    /api/v1/users/me
PATCH  /api/v1/users/me                    { full_name, bio, skill_ids, privacy_level, ... }
DELETE /api/v1/users/me                                                  # RF-31
GET    /api/v1/users/me/data-export                                      # RF-30
POST   /api/v1/users/me/avatar             multipart file
GET    /api/v1/users/search?q&institution&course
GET    /api/v1/users/:id
GET    /api/v1/users/me/blocks                                           # RF-15
POST   /api/v1/users/me/blocks/:userId
DELETE /api/v1/users/me/blocks/:userId
GET    /api/v1/connections?status=accepted|pending&direction=received|sent
POST   /api/v1/connections                  { addressee_id }
PATCH  /api/v1/connections/:id              { action: accept|reject }
DELETE /api/v1/connections/:id
GET    /api/v1/skills
```

### Feed
```
GET    /api/v1/posts?scope=local|global&cursor&limit
POST   /api/v1/posts                       { content, scope } OR multipart with file
DELETE /api/v1/posts/:id
POST   /api/v1/posts/:id/reactions         { type: like|insightful|support }   # RF-21
DELETE /api/v1/posts/:id/reactions
GET    /api/v1/posts/:id/comments?cursor
POST   /api/v1/posts/:id/comments          { content, parent_comment_id? }      # RF-22
```

### Mensagens
```
GET    /api/v1/chats
POST   /api/v1/chats                       { type, member_ids, name? }          # RF-23/24
GET    /api/v1/chats/:id
GET    /api/v1/chats/:id/messages?cursor
POST   /api/v1/chats/:id/messages          { content } OR multipart with file   # RF-25/27
POST   /api/v1/chats/:id/members           { user_id }
DELETE /api/v1/chats/:id/members/:userId
```

### Notificações
```
GET    /api/v1/notifications?unread=true                                 # RF-35
PATCH  /api/v1/notifications/:id/read
PATCH  /api/v1/notifications/read-all
```

### Moderação
```
POST   /api/v1/reports                     { target_type, target_id, reason }   # RF-40
GET    /api/v1/reports                                                  # RF-39
PATCH  /api/v1/reports/:id                 { action: resolve|dismiss }
```

### Administração
```
GET    /api/v1/institutions                                              # público
POST   /api/v1/institutions                { name, slug, domains }       # RF-37 (admin)
PATCH  /api/v1/institutions/:id/domains    { add: [], remove: [] }       # RF-38 (admin)
```

### WebSocket
```
WS  ws://localhost:3004/ws  (auth via { token } no handshake)
Eventos cliente → servidor:
  message:send    { chatId, content }
  typing:start    { chatId }
  typing:stop     { chatId }

Eventos servidor → cliente:
  message:new       (Message)
  typing:indicator  { chatId, userId, isTyping }
```

---

## 8. Banco de dados

### Schemas

| Schema | Tabelas principais | Owner |
|---|---|---|
| `auth` | `institutions`, `user_credentials`, `refresh_tokens`, `consent_records`, `otp_codes` (Redis) | auth-service |
| `profile` | `users`, `skills`, `user_skills`, `user_links`, `connections`, `user_blocks` | profile-service |
| `feed` | `posts`, `comments`, `reactions`, `reports` | feed-service |
| `messaging` | `chats`, `chat_members`, `messages`, `notifications` | messaging-service |
| `audit` | `audit_logs` | shared (todos os serviços) |

### Eventos no Redis (canal `interaedu.events`)

| Evento | Producer | Consumers |
|---|---|---|
| `user.registered` | auth-service | profile-service (cria perfil base) |
| `user.deletion_requested` | profile-service | profile-service (anonimização) — RN-10 |
| `user.consent_revoked` | auth-service | (futuro: triggers de moderação) |

---

## 9. Cobertura do SRS

```
RF-01 ✅  RF-02 ✅  RF-03 ✅  RF-04 ✅  RF-05 ✅  RF-06 ✅  RF-07 ✅  RF-08 ✅
RF-09 ✅  RF-10 ✅  RF-11 ✅  RF-12 ✅  RF-13 ✅  RF-14 ✅  RF-15 ✅  RF-16 ✅
RF-17 ✅  RF-18 ✅  RF-19 ✅  RF-20 ✅  RF-21 ✅  RF-22 ✅  RF-23 ✅  RF-24 ✅
RF-25 ✅  RF-26 ✅  RF-27 ✅  RF-28 ✅  RF-29 ✅  RF-30 ✅  RF-31 ✅  RF-32 ✅
RF-33 ✅  RF-34 ❌  RF-35 ✅  RF-36 ❌  RF-37 ✅  RF-38 ✅  RF-39 ✅  RF-40 ✅

RN-01 ✅  RN-02 ✅  RN-03 ✅  RN-04 ✅  RN-05 ✅  RN-06 ✅  RN-07 ✅  RN-08 ✅
RN-09 ✅  RN-10 ✅

Total: 45 de 50 ✅
```

**Pendentes intencionais:**
- **RF-34, RF-36** — Push notifications via Firebase Cloud Messaging. Web não tem fluxo nativo de FCM sem service worker; ficou para a versão mobile.
- **B-03** — Login com Google: backend e frontend prontos, falta operador cadastrar o OAuth Client ID no Google Cloud Console.

---

## 10. O que falta para produção

| Categoria | Item | Esforço |
|---|---|---|
| Infra | Deploy em cloud (AWS/GCP/Azure) | M |
| Infra | TLS via cert-manager ou ACM | S |
| Infra | Secrets management (Vault, AWS SM ou Doppler) | S |
| Infra | Backup automatizado do Postgres + WAL archiving | S |
| Infra | SMTP real (SendGrid, SES, Mailgun) — hoje OTP só no log | XS |
| Infra | Logs estruturados em JSON (Pino) | S |
| Infra | Tracing distribuído (OpenTelemetry + Jaeger) | M |
| Infra | Alertas Prometheus (5xx, p95, queue depth, DB down) | S |
| Infra | Métricas `/metrics` em auth/profile/feed/messaging (hoje só gateway) | S |
| Infra | Postgres encryption at rest (AES-256) | S |
| CI/CD | GitHub Actions: lint → test → build → push → deploy | M |
| Qualidade | OWASP Top 10 scan (ZAP, Burp) | M |
| Qualidade | WCAG 2.1 AA audit (axe-core + leitor de tela) | M |
| Qualidade | Load test (RNF-08: 100K MAU) | M |
| Operação | Cron job de retenção (90d soft delete, 5y logs) | S |
| Mobile | Build Android/iOS + Firebase Cloud Messaging | L |
| Mobile | Push notifications + config de tipos (RF-34/36) | M |
| Admin | Aplicação web admin separada (SPA) | M |

**Estimativa total:** 4 a 6 semanas até deploy seguro em ambiente produtivo.

---

## 11. Estrutura do projeto

```
intera_edu/
├── README.md                       # README do projeto
├── README_MOBILE.md                # README do app Flutter
├── IMPLEMENTACAO.md                # Este arquivo
├── docs/
│   ├── README.md                   # Índice central da documentação
│   ├── walkthrough-sessao.md       # Walkthrough cronológico das mudanças
│   ├── arquitetura/                # 9 documentos arquiteturais
│   │   ├── visao-produto.md
│   │   ├── requisitos.md           # SRS oficial
│   │   ├── sistema.md
│   │   ├── microsservicos.md
│   │   ├── dados.md
│   │   ├── api.md
│   │   ├── seguranca.md
│   │   ├── devops.md
│   │   └── escalabilidade.md
│   ├── guias/
│   │   ├── padroes-desenvolvimento.md
│   │   └── tarefas-ia.md
│   └── mvp/
│       └── status-implementacao.md # Tabela ✅/⏳/❌ de cada RF
├── backend/                        # NestJS workspace
│   ├── docker-compose.yml          # 10 containers
│   ├── package.json                # workspaces npm
│   ├── package-lock.json
│   ├── tsconfig.base.json
│   ├── scripts/
│   │   ├── init-db.sql             # cria schemas
│   │   └── seed-demo.sql           # popula usuários + posts demo
│   ├── observability/
│   │   ├── prometheus.yml
│   │   └── grafana/
│   │       ├── provisioning/
│   │       └── dashboards/
│   ├── shared/                     # @interaedu/shared
│   │   └── src/
│   │       ├── auth/               # JwtAuthGuard, JwtStrategy, CurrentUser
│   │       ├── database/
│   │       ├── redis/
│   │       └── audit/              # ✨ RF-33 audit log + interceptor
│   ├── gateway/                    # API Gateway (3000)
│   │   └── src/
│   │       ├── proxy/
│   │       │   ├── proxy.controller.ts
│   │       │   └── multipart-proxy.middleware.ts   # streaming multipart
│   │       ├── throttling/
│   │       │   └── path-aware-throttler.guard.ts   # rate limit
│   │       └── metrics/
│   │           ├── metrics.module.ts
│   │           └── metrics.middleware.ts
│   ├── auth-service/               # 3001
│   │   └── src/
│   │       ├── auth/
│   │       │   ├── auth.controller.ts
│   │       │   ├── auth.service.ts        # login, refresh, forgot, reset, accept-terms, revoke-consent
│   │       │   ├── google-auth.service.ts # RF-03 OAuth
│   │       │   └── dto/
│   │       ├── otp/
│   │       ├── institution/
│   │       │   ├── institution.controller.ts  # ✨ RF-37/38
│   │       │   └── institution.service.ts
│   │       └── database/
│   ├── profile-service/            # 3002
│   │   └── src/
│   │       ├── profile/
│   │       │   ├── profile.controller.ts
│   │       │   ├── profile.service.ts     # RF-30 export, RF-31 deletion
│   │       │   ├── s3.service.ts          # B-02 avatar upload
│   │       │   └── dto/
│   │       ├── skills/
│   │       ├── connections/                # RF-13/14 enriched
│   │       ├── blocks/                     # ✨ RF-15
│   │       ├── events/
│   │       │   └── events.subscriber.ts   # RN-10 anonimização
│   │       └── database/
│   ├── feed-service/               # 3003
│   │   └── src/
│   │       ├── posts/
│   │       │   ├── posts.controller.ts    # ✨ RF-16 multipart
│   │       │   ├── posts.service.ts       # RN-03 forced exploration
│   │       │   └── s3.service.ts
│   │       ├── feed/
│   │       ├── reports/                    # ✨ RF-39/40
│   │       └── database/
│   ├── messaging-service/          # 3004
│   │   └── src/
│   │       ├── chats/
│   │       │   ├── chats.controller.ts    # RF-24/25 grupos + RF-27 multipart
│   │       │   ├── chats.service.ts
│   │       │   └── s3.service.ts
│   │       ├── notifications/              # ✨ RF-35
│   │       ├── websocket/
│   │       │   └── chat.gateway.ts        # RF-23/28
│   │       └── database/
│   └── ...
├── lib/                            # Flutter
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── auth/
│   │   │   ├── auth_notifier.dart
│   │   │   ├── google_sign_in_web.dart    # B-03 GIS interop
│   │   ├── config/app_config.dart
│   │   ├── design/                         # AppTokens (cores, sombras)
│   │   ├── di/service_locator.dart
│   │   ├── network/
│   │   │   ├── api_client.dart            # auth interceptor + refresh
│   │   │   ├── api_endpoints.dart
│   │   │   └── socket_service.dart        # auto-connect on auth
│   │   ├── router/app_router.dart
│   │   ├── storage/secure_storage.dart
│   │   ├── theme/
│   │   ├── utils/validators.dart
│   │   └── widgets/                        # GradientButton, GlassBottomNav, StitchCard
│   ├── data/
│   │   ├── models/                         # *_model.dart com fromJson
│   │   └── repositories/                   # *_repository_impl.dart
│   ├── domain/
│   │   ├── entities/                       # Post, Chat, User, Skill, ...
│   │   └── repositories/                   # interfaces abstratas
│   └── presentation/
│       ├── auth/
│       │   └── screens/
│       │       ├── login_screen.dart
│       │       ├── register_screen.dart
│       │       ├── otp_screen.dart
│       │       └── forgot_password_screen.dart   # ✨ RF-06
│       ├── onboarding/screens/
│       │   ├── welcome_screen.dart
│       │   └── profile_setup_screen.dart
│       ├── feed/
│       │   ├── screens/
│       │   │   ├── feed_screen.dart
│       │   │   └── create_post_screen.dart        # RF-16 anexo
│       │   ├── widgets/
│       │   │   ├── post_card.dart                 # RF-21 picker + RF-22 + denunciar
│       │   │   └── comments_sheet.dart            # RF-22 nested
│       │   └── notifiers/feed_notifier.dart
│       ├── profile/
│       │   ├── screens/
│       │   │   ├── my_profile_screen.dart         # avatar + perfil
│       │   │   ├── edit_profile_screen.dart
│       │   │   ├── user_profile_screen.dart       # menu bloquear/denunciar
│       │   │   ├── search_screen.dart             # filtros funcionais
│       │   │   └── connections_screen.dart
│       │   └── notifiers/profile_notifier.dart
│       ├── messages/
│       │   ├── screens/
│       │   │   ├── chats_list_screen.dart
│       │   │   ├── chat_room_screen.dart          # RF-27 attach
│       │   │   └── create_group_screen.dart       # ✨ RF-24
│       │   └── notifiers/
│       ├── notifications/
│       │   └── screens/notifications_screen.dart  # ✨ RF-35
│       ├── settings/
│       │   └── screens/settings_screen.dart       # ✨ RF-30/31/32
│       ├── admin/
│       │   └── screens/admin_screen.dart          # ✨ RF-37/38/39
│       └── shared/                                 # UserAvatar, ErrorRetryWidget, ...
└── web/index.html                  # Google Identity Services script
```

---

## 12. Cronologia das mudanças

> Para detalhes técnicos cronológicos veja [docs/walkthrough-sessao.md](docs/walkthrough-sessao.md).

### Semana 1 — Onboarding visual + ativação local
- Skin Stitch aplicado em Welcome, Register, Login
- Docker Desktop + `docker compose up --build` (10 containers)
- Seed de 7 usuários demo
- Hot keyboard no AVD Android (eventualmente abandonado em favor de web)

### Semana 2 — M-07 Chat real-time + B-02 avatar
- WebSocket auto-conecta no `AuthNotifier` quando autenticado
- Botão "Mensagem" no perfil cria chat direto
- Upload de avatar via MinIO (multipart pelo gateway)
- B-05 rate limiting no gateway com bucket por IP+namespace

### Semana 3 — Observabilidade + correções de bugs
- Prometheus + Grafana ao docker-compose
- Gateway expõe `/metrics` com histograma de duração HTTP
- Multipart proxy middleware no gateway (streaming)
- Correções: cast `_JsonMap` no go_router, fallback de avatar quando NetworkImage falha, contador de comentários sincronizado, conexões enriquecidas com `other_user`, filtros do Explorar funcionais

### Semana 4 — Sprint de funcionalidades P1 + LGPD + Admin
- RF-06 esqueci minha senha (backend + frontend)
- RF-15 bloquear usuário
- RF-21 reações em 3 tipos
- RF-22 respostas aninhadas
- RF-24/25 grupos de estudo
- RF-27 arquivos em chat
- RF-35 central de notificações
- RF-37/38/39 admin UI + endpoints
- RF-40 botão denunciar
- RF-30 exportação de dados
- RF-31 exclusão de conta com cascade
- RF-32 revogar consentimento
- RF-33 trilha de auditoria
- RN-09 re-consentimento
- RN-10 deleção em cascata
- RF-16 upload de arquivo em post

---

## 13. Roteiro de demonstração

> Roteiro de 8–10 minutos para apresentar o produto.

1. **Welcome** (15s) — tese do produto (quebrar silos)
2. **Login** com `joao@ufmg.br` (30s)
3. **Feed Local** → criar post com texto + anexo PDF (1min)
4. **Reagir** long-press → escolher "Perspicaz" (15s)
5. **Comentar** → responder ao próprio comentário (replies aninhadas) (45s)
6. **Toggle pra Global** → mostrar posts da USP/Unicamp na lista (RN-03 visível) (30s)
7. **Aba Explorar** → filtrar por habilidade "Machine Learning" → ver Ana sugerida (45s)
8. **Conectar** com Ana → aceitar do outro lado (em janela anônima) (1min)
9. **Mensagem** direta com Ana → enviar texto + arquivo (1min)
10. **FAB "Novo grupo"** → criar com 2-3 membros → mandar mensagem (1min)
11. **Sino 🔔** → mostrar central de notificações (15s)
12. **Engrenagem ⚙️ → Configurações** → mostrar 3 ações LGPD; exportar dados → JSON bonitinho (45s)
13. **URL /admin** → mostrar Instituições + Denúncias (30s)
14. **Grafana** localhost:3030 → dashboard com métricas em tempo real (30s)
15. **MinIO Console** localhost:9001 → ver avatares e anexos uploadados (15s)

---

## 14. Limitações conhecidas

- **Hot reload do Flutter Web** instável no Windows + Git Bash (DWDS perde conexão se Chrome fechar). Solução: usar `-d web-server` + F5 manual.
- **OTP** só vai pra `docker logs interaedu-auth-service`. Em produção, plugar SMTP real.
- **Google OAuth** não está ativo (CLIENT_ID vazio); botão escondido por flag.
- **Push FCM** não implementado.
- **Save (bookmark) no PostCard** é visual; não persiste no banco.
- **Hamburger menu** não tem drawer ainda.
- **Avatar fallback** mostra inicial; URLs do Pravatar dependem da rede externa.

---

## 15. Créditos e referências

Documentação técnica consolidada em [`docs/README.md`](docs/README.md):
- [SRS](docs/arquitetura/requisitos.md) — fonte da verdade dos requisitos
- [Visão de Produto](docs/arquitetura/visao-produto.md)
- [API](docs/arquitetura/api.md)
- [Segurança](docs/arquitetura/seguranca.md)
- [DevOps](docs/arquitetura/devops.md)

Walkthroughs:
- [Walkthrough da Sessão de Implementação](docs/walkthrough-sessao.md) — cronologia detalhada
- [Walkthrough da Refatoração de Docs](docs/walkthrough.md)

Status atualizado:
- [Status de Implementação MVP](docs/mvp/status-implementacao.md)

---

**Última atualização:** Junho 2026
**Cobertura SRS:** 45 / 50 (90%)
**Pronto para:** Demo, validação, testes de aceitação
**Falta para produção:** Infra de cloud (deploy, TLS, secrets, observability completa) + push mobile
