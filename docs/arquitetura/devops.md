# InteraEdu — Arquitetura DevOps

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Estrutura de Contêineres

### 1.1 Contêineres de Serviços (Microsserviços)

| Contêiner | Imagem Base | Porta | Propósito |
|:---|:---|:---|:---|
| `gateway` | `node:20-alpine` | 3000 | API Gateway (NestJS) |
| `auth-service` | `node:20-alpine` | 3001 | Serviço de Autenticação |
| `profile-service` | `node:20-alpine` | 3002 | Serviço de Perfil |
| `feed-service` | `node:20-alpine` | 3003 | Serviço de Feed |
| `messaging-service` | `node:20-alpine` | 3004 | Serviço de Mensageria |

### 1.2 Contêineres de Infraestrutura Local

| Contêiner | Imagem | Porta | Propósito |
|:---|:---|:---|:---|
| `postgres` | `postgres:16-alpine` | 5432 | Banco de dados principal |
| `redis` | `redis:7-alpine` | 6379 | Cache, pub/sub e sessões |
| `minio` | `minio/minio` | 9000 | Object storage compatível com S3 (desenvolvimento) |

### 1.3 Modelo de Dockerfile (por serviço)

```dockerfile
# Build multi-stage para produção
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

## 2. Pipeline de CI/CD

### 2.1 Workflow do GitHub Actions

```yaml
# .github/workflows/ci.yml
name: Pipeline CI/CD

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
      - name: Deploy para Staging
        run: echo "Deploy para o cluster Kubernetes de staging"
        # kubectl apply / helm upgrade

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy para Produção
        run: echo "Deploy para o cluster Kubernetes de produção"
```

### 2.2 Etapas do Pipeline

```text
Push de Código → Lint → Testes Unitários → Testes E2E → Build Docker → Push para Registry
                                                               │
                                             ┌─────────────────┴─────────────────┐
                                             │                                   │
                                     Deploy Staging                       Deploy Produção
                                     (automático)                         (aprovação manual)
```

---

## 3. Estratégia de Ambientes

### 3.1 Ambientes

| Ambiente | Propósito | Infraestrutura | Branch |
|:---|:---|:---|:---|
| **Local** | Workstation do desenvolvedor | Docker Compose | Qualquer |
| **CI** | Testes automatizados | GitHub Actions runners | Branches de PR |
| **Staging (Homologação)** | Validação pré-produção | Cloud (escala reduzida) | `main` (automático) |
| **Produção** | Sistema em produção | Cloud (escala completa) | `main` (aprovação manual) |

### 3.2 Variáveis de Ambiente

Todos os serviços compartilham uma estrutura `.env` comum:

```bash
# Aplicação
NODE_ENV=development          # development | staging | production
SERVICE_NAME=auth-service
SERVICE_PORT=3001

# Banco de dados
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
JWT_ACCESS_SECRET=seu-access-secret-aqui
JWT_REFRESH_SECRET=seu-refresh-secret-aqui
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# E-mail (para OTP)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=sua-chave-sendgrid

# S3 (Object Storage)
S3_ENDPOINT=http://minio:9000
S3_BUCKET=interaedu
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_REGION=us-east-1

# Firebase (Notificações Push)
FIREBASE_PROJECT_ID=interaedu
FIREBASE_CREDENTIALS_PATH=./firebase-key.json
```

---

## 4. Gerenciamento de Segredos

### 4.1 Estratégia por Ambiente

| Ambiente | Armazenamento de Segredos |
|:---|:---|
| Local | Arquivo `.env` (no gitignore) |
| CI | GitHub Secrets |
| Staging/Produção | Cloud KMS (AWS Secrets Manager / GCP Secret Manager) |

### 4.2 Segredos Sensíveis

| Segredo | Utilizado por |
|:---|:---|
| `JWT_ACCESS_SECRET` | Auth Service, Gateway |
| `JWT_REFRESH_SECRET` | Auth Service |
| `DATABASE_PASSWORD` | Todos os serviços |
| `REDIS_PASSWORD` | Todos os serviços |
| `SMTP_PASSWORD` | Auth Service |
| `S3_SECRET_KEY` | Feed Service, Messaging Service |
| `FIREBASE_CREDENTIALS` | Messaging Service (notificações push) |

### 4.3 Rotação de Segredos
- **Segredos JWT**: Rotação trimestral. Suportar validação com duas chaves simultaneamente durante a janela de rotação.
- **Senhas do banco de dados**: Rotação mensal em produção.
- **Chaves de API (SendGrid, Firebase)**: Rotacionar em caso de saída de membros do time.

---

## 5. Monitoramento e Observabilidade

### 5.1 Métricas (Prometheus)

Cada serviço NestJS expõe um endpoint `/metrics` (via `@willsoto/nestjs-prometheus`).

**Métricas principais:**

| Métrica | Tipo | Descrição |
|:---|:---|:---|
| `http_requests_total` | Counter | Total de requisições HTTP por método, rota e status |
| `http_request_duration_seconds` | Histogram | Distribuição de latência das requisições |
| `active_websocket_connections` | Gauge | Conexões WebSocket ativas no momento |
| `database_query_duration_seconds` | Histogram | Latência das queries ao banco |
| `redis_operations_total` | Counter | Operações no Redis por comando |
| `auth_login_attempts_total` | Counter | Tentativas de login por resultado (sucesso/falha) |
| `otp_verification_attempts_total` | Counter | Tentativas de verificação de OTP por resultado |
| `feed_cache_hits_total` | Counter | Taxa de acerto/erro de cache do feed |

### 5.2 Dashboards (Grafana)

| Dashboard | Painéis |
|:---|:---|
| **Saúde dos Serviços** | Taxa de requisições, taxa de erros, latência (p50/p95/p99), uptime |
| **Autenticação** | Taxa de login, sucesso de OTP, renovações de token, IPs bloqueados |
| **Performance do Feed** | Tempo de carregamento, taxa de acerto do cache, taxa de criação de posts |
| **Mensageria** | Conexões WebSocket, throughput de mensagens, latência de entrega |
| **Infraestrutura** | CPU/Memória por contêiner, conexões no PostgreSQL, memória do Redis |

### 5.3 Logs

**Logs JSON estruturados** via Pino:

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
  "message": "Login realizado com sucesso"
}
```

**Níveis de log por ambiente:**

| Ambiente | Nível |
|:---|:---|
| Local | `debug` |
| Staging | `info` |
| Produção | `warn` |

### 5.4 Rastreamento Distribuído

- **OpenTelemetry SDK** integrado a cada serviço.
- **Propagação de trace** via header `traceparent` (W3C Trace Context).
- **Exportação para**: Jaeger (desenvolvimento) ou rastreamento nativo da nuvem (AWS X-Ray / GCP Cloud Trace).

### 5.5 Alertas

| Alerta | Condição | Severidade | Canal |
|:---|:---|:---|:---|
| Alta taxa de erros | > 5% de respostas 5xx em 5 minutos | Crítico | PagerDuty / Slack |
| Alta latência | p95 > 5s por 5 minutos | Aviso | Slack |
| Pool de conexões do banco esgotado | Conexões ativas > 90% | Crítico | PagerDuty |
| Pico de bloqueios no auth | > 50 bloqueios em 10 minutos | Aviso | Slack |
| Uso de disco alto | > 80% em qualquer volume | Aviso | Slack |

### 5.6 Health Checks

Cada serviço expõe:

| Endpoint | Propósito |
|:---|:---|
| `GET /health` | Liveness probe (retorna 200 se o processo está ativo) |
| `GET /health/ready` | Readiness probe (verifica conectividade com banco e Redis) |
