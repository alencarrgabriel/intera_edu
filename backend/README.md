# InteraEdu — Backend

## Visão Geral

O backend do InteraEdu é uma **arquitetura de microserviços** construída com **NestJS + TypeScript**. Cada serviço é autônomo, possui seu próprio schema PostgreSQL e se comunica via HTTP (síncrono) e Redis Pub/Sub (assíncrono/eventos).

---

## Propósito do Módulo

Fornecer toda a lógica de negócio da plataforma: autenticação institucional, perfis de usuários, feed de postagens, conexões entre acadêmicos e mensagens em tempo real.

---

## Responsabilidades

| Serviço | Porta | Responsabilidade |
|---|---|---|
| `gateway` | 3000 | Proxy reverso, autenticação JWT, roteamento |
| `auth-service` | 3001 | Registro com OTP, login, refresh token, consentimento |
| `profile-service` | 3002 | Perfil, habilidades, conexões, eventos, busca |
| `feed-service` | 3003 | Posts, reações, comentários, feed local/global |
| `messaging-service` | 3004 | Chats, mensagens, WebSocket |
| `shared` | — | Biblioteca interna: JWT, Redis, DTOs, interfaces |

---

## Tecnologias Utilizadas

- **NestJS** — Framework Node.js orientado a módulos
- **TypeScript** — Tipagem estática
- **TypeORM** — ORM para PostgreSQL
- **PostgreSQL 16** — Banco de dados relacional (schemas separados por serviço)
- **Redis 7** — Cache de feed, pub/sub de eventos, armazenamento de OTP
- **MinIO** — Object storage (S3-compatível) para mídias
- **Bcrypt** — Hash de senhas e refresh tokens
- **JWT (jsonwebtoken)** — Access token (15m) + Refresh token (7d) com rotação
- **Helmet** — Headers de segurança HTTP
- **Docker / Docker Compose** — Infraestrutura local

---

## Estrutura do Projeto

```
backend/
├── docker-compose.yml          # Orquestração de todos os serviços + infra
├── .env.example                # Variáveis de ambiente modelo
├── tsconfig.base.json          # Configuração base TypeScript compartilhada
├── package.json                # Scripts de workspace
├── scripts/
│   └── init-db.sql             # Script de inicialização do banco de dados
├── shared/                     # Pacote NPM interno @interaedu/shared
│   └── src/
│       ├── auth/               # Guard JWT, decorators (@Public, @CurrentUser)
│       ├── database/           # Configuração TypeORM base
│       ├── redis/              # RedisService (get/set/publish/subscribe)
│       ├── dto/                # DTOs compartilhados
│       └── interfaces/         # JwtPayload interface
├── gateway/                    # API Gateway (proxy reverso)
│   └── src/
│       ├── proxy/              # Módulo de proxy HTTP para serviços
│       └── main.ts             # Boot: helmet, CORS, ValidationPipe, prefixo /api/v1
├── auth-service/               # Serviço de autenticação
│   └── src/
│       ├── auth/               # Controller + Service + DTOs
│       ├── otp/                # Geração e verificação de OTP via Redis
│       ├── institution/        # Validação de domínio institucional
│       └── database/           # Entidades: UserCredential, RefreshToken, ConsentRecord
├── profile-service/            # Serviço de perfis
│   └── src/
│       ├── profile/            # Controller + Service (CRUD perfil, busca, privacidade)
│       ├── skills/             # Skills disponíveis e habilidades do usuário
│       ├── connections/        # Solicitações e gerenciamento de conexões
│       ├── events/             # Eventos acadêmicos criados por usuários
│       └── database/           # Entidades: UserProfile, Skill, UserSkill, Connection, UserLink
├── feed-service/               # Serviço de feed e postagens
│   └── src/
│       ├── posts/              # Controller + Service (CRUD posts, reações, comentários)
│       ├── feed/               # Lógica de feed local vs global
│       └── database/           # Entidades: PostEntity, ReactionEntity, CommentEntity
└── messaging-service/          # Serviço de mensagens
    └── src/
        ├── chats/              # Controller + Service (criação e listagem de chats)
        └── websocket/          # Gateway WebSocket para mensagens em tempo real
```

---

## Como Rodar

### Pré-requisitos

- **Docker Desktop** (>= 24.x) com Docker Compose v2
- **Node.js 20+** (apenas para desenvolvimento local sem Docker)

### Instalação e Execução (Docker — recomendado)

```bash
# 1. Entre na pasta backend
cd backend

# 2. Copie o arquivo de variáveis de ambiente
cp .env.example .env
# Edite .env conforme necessário

# 3. Suba toda a stack
docker-compose up --build

# 4. Para rodar em background
docker-compose up -d --build
```

### Acesso aos Serviços

| Serviço | URL |
|---|---|
| API Gateway | http://localhost:3000/api/v1 |
| Auth Service (direto) | http://localhost:3001 |
| Profile Service (direto) | http://localhost:3002 |
| Feed Service (direto) | http://localhost:3003 |
| Messaging Service (direto) | http://localhost:3004 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |
| MinIO Console | http://localhost:9001 |

### Variáveis de Ambiente Principais

| Variável | Descrição | Padrão |
|---|---|---|
| `DATABASE_HOST` | Host do PostgreSQL | `postgres` |
| `DATABASE_SCHEMA` | Schema do serviço | ex: `auth`, `profile` |
| `JWT_ACCESS_SECRET` | Segredo do access token | — |
| `JWT_REFRESH_SECRET` | Segredo do refresh token | — |
| `JWT_ACCESS_EXPIRATION` | Expiração do access token | `15m` |
| `JWT_REFRESH_EXPIRATION` | Expiração do refresh token | `7d` |
| `REDIS_HOST` | Host do Redis | `redis` |
| `SMTP_HOST` | Host SMTP para E-mails | `mailhog` |

---

## Integração

### Fluxo Principal: Mobile → Gateway → Microserviço → DB

```
Mobile App
    │ HTTP REST (Bearer JWT)
    ▼
Gateway (:3000)
    │ valida JWT
    │ proxy para serviço correto
    ┌────────────────────┐
    ▼                    ▼
Auth (:3001)     Profile (:3002)
    │
    ▼
PostgreSQL (schemas separados) + Redis (cache/OTP/eventos)
```

### Eventos Assíncronos (Redis Pub/Sub)

| Evento | Produtor | Consumidor |
|---|---|---|
| `user.registered` | auth-service | profile-service (criação de perfil inicial) |
| `post.created` | feed-service | — (futuro: notificações) |

---

## Convenções e Padrões

### Arquitetura

- **Módulos NestJS por domínio**: cada feature é um módulo independente (`AuthModule`, `PostsModule`, etc.)
- **Shared library** `@interaedu/shared`: nunca duplicar lógica de JWT, Redis ou Guards entre serviços
- **Schema PostgreSQL isolado por serviço**: `auth`, `profile`, `feed`, `messaging` — nunca JOINs cross-schema

### Padrões de Código

- Todos os arquivos em **TypeScript estrito**
- DTOs com `class-validator` para validação automática
- Services sem lógica de apresentação (apenas negócio)
- Controllers sem lógica de negócio (apenas delegação)
- Usar `Logger` do NestJS em vez de `console.log`

### Padrões de API

- Prefixo: `/api/v1`
- Formato de erro padrão:
  ```json
  { "error": { "code": "SNAKE_CASE_CODE", "message": "Mensagem legível" } }
  ```
- Paginação por cursor (base64 encode de timestamp `{ t: ISO_STRING }`)
- IDs no formato UUID v4
- Datas em ISO 8601 UTC

### Regras Importantes

- **NUNCA** armazenar refresh token em texto plano — sempre hash com bcrypt
- **SEMPRE** validar o domínio de e-mail contra a tabela de instituições no registro
- **SEMPRE** usar `@Public()` decorator em endpoints que não precisam de JWT
- **NUNCA** fazer joins entre schemas de serviços diferentes — usar chamadas HTTP
- Soft delete: campo `deleted_at` (nunca deletar registros fisicamente em produção)
