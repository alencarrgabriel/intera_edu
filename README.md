# InteraEdu — Plataforma de Networking Acadêmico

> Conectando mentes, expandindo o conhecimento sem fronteiras.

O **InteraEdu** é uma plataforma de networking acadêmico interuniversitário. Nossa missão é quebrar os "silos" institucionais, permitindo que estudantes e pesquisadores colaborem com base em habilidades e interesses, promovendo uma cultura de **Mastery Orientation**.

---

## 🚀 Funcionalidades Principais

- **Autenticação Institucional** — Acesso exclusivo via e-mails educacionais (`.edu.br`) validados por OTP
- **Busca Interuniversitária** — Encontre pares com habilidades complementares em qualquer IES do país
- **Feed Híbrido** — Alterne entre Feed Local (sua universidade) e Feed Global (toda a base) com algoritmo _Force Exploration_ (≥20% conteúdo de outras IES)
- **Mensagens em Tempo Real** — Chat 1:1 e grupos de estudo via WebSocket (Socket.IO)
- **Privacy by Design** — Controle granular de visibilidade (público, local, privado) em conformidade com a LGPD

---

## 🏗️ Arquitetura

| Camada | Tecnologia |
|:---|:---|
| **Mobile** | Flutter (Dart) — Clean Architecture |
| **API Gateway** | NestJS com rate limiting e proxy reverso |
| **Microsserviços** | NestJS (TypeScript) — Auth, Profile, Feed, Messaging |
| **Banco de Dados** | PostgreSQL 16 (esquema por serviço com RLS) |
| **Cache / Pub-Sub** | Redis 7 (cache, sessões, WebSocket fan-out) |
| **Object Storage** | MinIO (dev) / S3 (produção) |
| **CI/CD** | GitHub Actions → Docker → Kubernetes |

```
┌─────────────┐
│  Flutter App │
└──────┬──────┘
       │ HTTPS
┌──────▼──────┐
│  API Gateway │  (porta 3000)
│   (NestJS)   │
└──┬───┬───┬──┘
   │   │   │
┌──▼┐ ┌▼──┐ ┌▼───────────┐
│Auth│ │Pro│ │Feed │ Msg  │
│3001│ │3002│ │3003 │ 3004│
└──┬─┘ └─┬─┘ └──┬──┴──┬──┘
   │     │      │     │
┌──▼─────▼──────▼─────▼──┐
│     PostgreSQL + Redis   │
└──────────────────────────┘
```

---

## 📖 Documentação

Toda a documentação técnica está na pasta [`docs/`](docs/), organizada na seguinte ordem de leitura:

| # | Documento | Conteúdo |
|:--|:----------|:---------|
| 01 | [Visão do Produto](docs/01_product_vision.md) | Personas, métricas de sucesso, análise competitiva, escopo |
| 02 | [Especificação de Requisitos (SRS)](docs/02_srs.md) | 40 requisitos funcionais, 14 não-funcionais, casos de uso |
| 03 | [Arquitetura do Sistema](docs/03_system_architecture.md) | Topologia de serviços, padrões de comunicação, diagramas |
| 04 | [Design de Microsserviços](docs/04_microservices_design.md) | Contratos por serviço, fluxos de eventos, ownership de dados |
| 05 | [Arquitetura de Dados](docs/05_data_architecture.md) | 20+ tabelas, índices, RLS, audit logs, soft deletes |
| 06 | [Design da API](docs/06_api_design.md) | Convenções REST, paginação por cursor, todos os endpoints |
| 07 | [Arquitetura de Segurança](docs/07_security_architecture.md) | Ciclo JWT, proteção OTP, rate limiting, modelo de ameaças |
| 08 | [Arquitetura DevOps](docs/08_devops_architecture.md) | Docker, CI/CD, monitoramento, alertas, gestão de segredos |
| 09 | [Estratégia de Escalabilidade](docs/09_scalability_strategy.md) | Cache, filas (BullMQ), busca, escala horizontal, DR |

---

## 📂 Estrutura do Projeto

```
intera_edu/
├── docs/                         # 9 documentos de arquitetura
├── backend/                      # Monorepo NestJS
│   ├── docker-compose.yml        # PostgreSQL, Redis, MinIO + serviços
│   ├── shared/                   # Biblioteca compartilhada (@interaedu/shared)
│   │   └── src/
│   │       ├── database/         # DatabaseModule (TypeORM)
│   │       ├── redis/            # RedisModule + RedisService
│   │       ├── auth/             # JwtStrategy, JwtAuthGuard, @CurrentUser
│   │       ├── dto/              # PaginationDto, ErrorResponseDto
│   │       └── interfaces/       # JwtPayload, PaginatedResponse
│   ├── gateway/                  # API Gateway (porta 3000)
│   ├── auth-service/             # Serviço de Autenticação (porta 3001)
│   ├── profile-service/          # Serviço de Perfis (porta 3002)
│   ├── feed-service/             # Serviço de Feed (porta 3003)
│   └── messaging-service/        # Serviço de Mensagens (porta 3004)
└── lib/                          # App Flutter (Clean Architecture)
    ├── core/                     # Config, tema, API client, storage
    ├── domain/                   # Entidades e contratos (repositories)
    ├── data/                     # Modelos e implementações
    └── presentation/             # Telas (auth, onboarding)
```

---

## 🛠️ Como Iniciar

### Pré-requisitos

- [Node.js](https://nodejs.org/) v20+
- [Docker](https://www.docker.com/) e Docker Compose
- [Flutter](https://docs.flutter.dev/get-started/install) SDK ^3.11.0

### Backend

```bash
# 1. Instalar dependências (todos os workspaces)
cd backend
npm install

# 2. Copiar variáveis de ambiente
cp .env.example .env

# 3. Subir infraestrutura (PostgreSQL, Redis, MinIO)
docker compose up -d postgres redis minio

# 4. Rodar serviços em desenvolvimento
# (em terminais separados ou use docker compose up)
cd auth-service && npm run start:dev
cd gateway && npm run start:dev
# ... repetir para os demais serviços
```

### Frontend (Flutter)

```bash
# 1. Instalar dependências
flutter pub get

# 2. Rodar o app
flutter run
```

---

## 🔒 Segurança

- **JWT** com Access Token (15 min) + Refresh Token com rotação (7 dias)
- **OTP** via e-mail institucional (6 dígitos, 5 tentativas, lockout de 15 min)
- **Rate Limiting** por IP e por usuário no API Gateway
- **RLS** (Row-Level Security) no PostgreSQL para isolamento multi-tenant
- **LGPD** — Exportação de dados, exclusão com anonimização, registros de consentimento

---

## 📊 Stack Tecnológica

| Categoria | Tecnologia |
|:---|:---|
| Mobile | Flutter 3.x / Dart |
| Backend | NestJS 10.x / TypeScript 5.x |
| Banco de Dados | PostgreSQL 16 |
| Cache | Redis 7 |
| Mensageria | BullMQ (filas) + Redis Pub/Sub (WebSocket) |
| WebSocket | Socket.IO + Redis Adapter |
| Object Storage | MinIO (dev) / AWS S3 (produção) |
| Containerização | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| Monitoramento | Prometheus + Grafana + Pino (logs) |
| Tracing | OpenTelemetry → Jaeger |

---

## 📝 Licença

Este projeto é de uso privado e acadêmico.

---

*InteraEdu — Conectando mentes, expandindo o conhecimento sem fronteiras.* 🎓
