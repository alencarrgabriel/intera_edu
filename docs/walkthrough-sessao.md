# Walkthrough da Sessão de Implementação

**Data:** Junho 2026
**Escopo:** Aplicação do skin do protótipo (Stitch) nas telas de onboarding, ativação do backend Docker em ambiente local, implementação das tarefas pendentes do MVP (M-07, B-02, B-05) e habilitação do app na web.

Este documento lista, em ordem cronológica, **todas as alterações de código e configuração** realizadas nesta sessão de desenvolvimento, com o "porquê" de cada uma.

---

## 1. Onboarding visual (skin do protótipo Stitch)

Os três HTMLs em `prototipo/` foram aplicados nas telas Flutter correspondentes. **Apenas o front-end** foi tocado — toda a lógica (validators, controllers, navegação) ficou intacta.

| Arquivo | Mudança |
|---|---|
| `lib/presentation/onboarding/screens/welcome_screen.dart` | Reescrita: logo `auto_stories` + badge `hub`, headline "InteraEdu" + "CURADORIA DIGITAL", ornamentos de fundo, LGPD no rodapé. Botões "Começar" / "Já tenho uma conta" preservados pra manter navegação. |
| `lib/presentation/auth/screens/register_screen.dart` | Reescrita: cabeçalho "Passo 1 de 5" com indicador de 5 barras, headline "Bem-vindo ao InteraEdu.", input estilizado com label uppercase e ícone `school`, aviso LGPD com cadeado, card "Acesso Exclusivo", botão gradiente "Próximo →". |
| `lib/presentation/auth/screens/login_screen.dart` | Reescrita: pill de marca, headline "Bem-vindo de volta.", card contêiner com sombra ambiente, campos com label flutuante, "Esqueci minha senha", divisor "OU", botão "Continuar com Google" (visual). Link "Criar conta acadêmica" passou a navegar para `/register` (antes era `context.pop()`). |
| `lib/core/router/app_router.dart` | Cast tolerante a `_JsonMap` no `profileSetup` builder. No web o `state.extra` é restaurado como `Map<String, dynamic>` em vez de `Map<String, String>`. |

---

## 2. Ativação do app em ambiente local

### Emulador Android (descontinuado nesta sessão)

| Mudança | Motivo |
|---|---|
| Iniciado emulador `flutter_emulator` (`Medium Phone API 35`) | Único dispositivo móvel disponível |
| `hw.keyboard=yes` em `C:\Users\USER\.android\avd\flutter_emulator.avd\config.ini` | Permitir digitação via teclado físico no emulador |

Posteriormente, abandonado em favor do alvo `web-server` devido a limitação de recursos da máquina.

### Web target

O app passou a rodar via `flutter run -d web-server --web-port=8090 --web-hostname=localhost`, com `dart-define`:
- `API_BASE_URL=http://localhost:3000/api/v1`
- `WS_BASE_URL=http://localhost:3004`
- `PROFILE_DIRECT_URL=http://localhost:3002`

---

## 3. Backend Docker em pé

### Inicialização

1. Docker Desktop instalado em `C:\Program Files\Docker\Docker\Docker Desktop.exe`
2. `docker compose up -d --build` em `backend/` constrói as 5 imagens NestJS (gateway + 4 serviços) + sobe Postgres 16, Redis 7, MinIO
3. Bucket MinIO `interaedu` criado com `mc mb local/interaedu` e `mc anonymous set download` para tornar avatares legíveis publicamente

### Configuração

| Arquivo | Mudança |
|---|---|
| `backend/docker-compose.yml` | Adicionado bloco `environment` no `profile-service` com variáveis `S3_*` apontando para `http://minio:9000` (interno) e `http://localhost:9000` (público) |

### Dados de teste presentes

| User | Email | Senha | Instituição |
|---|---|---|---|
| João | `joao@ufmg.br` | (definida no cadastro) | UFMG |
| Maria | `maria@usp.br` | `Senha@123` | USP |

Ambos com `privacy_level = 'public'` para permitir descoberta cross-institutional durante o desenvolvimento.

---

## 4. Auth — Mock devMode

Antes do backend estar pronto, foi adicionado um curto-circuito em `AuthRepositoryImpl.login()` para destravar o teste de UI sem rede:

| Arquivo | Mudança |
|---|---|
| `lib/data/repositories/auth_repository_impl.dart` | Quando `AppConfig.devMode == true`, login gera JWT `alg=none` localmente (`_saveDevTokens`) com `sub`/`email`/`exp` em base64Url e grava no `SecureStorage`. Em produção o caminho original (POST `/auth/login`) é mantido. |
| `lib/core/config/app_config.dart` | `devMode` foi `true` durante UI tests e voltou para `false` quando o backend subiu. Adicionado `profileDirectUrl` para uploads multipart (ver §5). |

---

## 5. M-07 — Chat em tempo real (WebSocket)

Quase todo o código existia (`SocketService`, `ChatRoomNotifier`, `ChatsListScreen`, `ChatRoomScreen`, backend `ChatGateway`). O único gap era que `SocketService.connect(token)` nunca era chamado, então o WebSocket nunca subia.

| Arquivo | Mudança |
|---|---|
| `lib/app.dart` | `SocketService` agora é um `ChangeNotifierProvider` com `lazy: false`. No `create` registra um listener no `AuthNotifier`: quando `isAuthenticated == true`, lê o access token do `SecureStorage` e chama `socket.connect(token)`; quando muda para `unauthenticated`, chama `socket.disconnect()`. |
| `lib/presentation/profile/screens/user_profile_screen.dart` | Botão **"Mensagem"** adicionado ao lado do botão "Conectar". `_openChat()` chama `MessagesNotifier.createDirectChat(userId)` e navega para `/chat/{chatId}` via `context.push`. Estado `_startingChat` controla spinner local. |

**Backend já estava pronto** (`backend/messaging-service/src/websocket/chat.gateway.ts`): namespace `/ws`, autenticação JWT no handshake, eventos `message:send` / `message:new` / `typing:start` / `typing:stop` / `typing:indicator`.

---

## 6. B-02 — Upload de avatar (MinIO)

### Backend

| Arquivo | Mudança |
|---|---|
| `backend/profile-service/package.json` | Adicionado `@aws-sdk/client-s3` ^3.600.0, `uuid` ^9.0.0 e devDeps `@types/multer`, `@types/uuid`. Regenerado `backend/package-lock.json` via `npm install --package-lock-only`. |
| `backend/profile-service/src/profile/s3.service.ts` | **Novo.** Wrapper sobre `@aws-sdk/client-s3` configurado para MinIO (`forcePathStyle: true`). No `onModuleInit` garante que o bucket existe (`HeadBucketCommand` → `CreateBucketCommand`). Método `putObject(key, body, contentType)` faz upload e devolve URL pública usando `S3_PUBLIC_ENDPOINT`. |
| `backend/profile-service/src/profile/profile.service.ts` | Método `uploadAvatar(userId, file)` valida MIME (`image/jpeg\|png\|webp`) e tamanho (≤5MB), gera key `avatars/{userId}/{uuid}.{ext}`, chama `S3Service.putObject`, persiste `user.avatarUrl` e retorna `{ avatar_url }`. |
| `backend/profile-service/src/profile/profile.controller.ts` | Endpoint `POST /users/me/avatar` com `@UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5MB } }))`. |
| `backend/profile-service/src/profile/profile.module.ts` | `S3Service` adicionado como `provider`. |
| `backend/profile-service/src/main.ts` | CORS habilitado (`cors: true`) para que o browser consiga chamar diretamente o serviço — necessário porque o gateway não encaminha multipart corretamente. |

### Frontend

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml` | + `file_picker: ^8.1.7` (cross-platform file picker), `http_parser: ^4.0.2` (para `MediaType`) |
| `lib/core/config/app_config.dart` | + `profileDirectUrl` (`http://localhost:3002` default) para upload direto bypassando o gateway |
| `lib/domain/repositories/profile_repository.dart` | Interface ganhou `uploadAvatar({ bytes, filename, mimeType }) → Future<String>` |
| `lib/data/repositories/profile_repository_impl.dart` | Implementa `uploadAvatar` com `http.MultipartRequest` para `${profileDirectUrl}/users/me/avatar`, com header `Authorization: Bearer <token>` lido do `SecureStorage`. Lida com erros estruturados do backend. |
| `lib/presentation/profile/notifiers/profile_notifier.dart` | Método `uploadAvatar()` delega ao repo e força `load(force: true)` para atualizar a UI |
| `lib/presentation/profile/screens/my_profile_screen.dart` | Substituído o placeholder "Upload em breve" por `_pickAndUploadAvatar()` real: `FilePicker.platform.pickFiles(type: FileType.image, withData: true)`, lê bytes, deduz MIME pela extensão, faz upload, mostra SnackBar de sucesso. Spinner no badge do avatar enquanto faz upload. |

### Limitação conhecida

O gateway (`backend/gateway/src/proxy/proxy.service.ts`) força `Content-Type: application/json` no axios e usa `req.body`, que está vazio em requisições multipart (Express só parseia JSON). Como solução pragmática, o app chama diretamente `localhost:3002/users/me/avatar`. **Próximo passo:** reescrever o proxy para streamar o body bruto quando `Content-Type` começar com `multipart/`.

---

## 7. B-05 — Rate limiting no gateway

| Arquivo | Mudança |
|---|---|
| `backend/gateway/src/throttling/path-aware-throttler.guard.ts` | **Novo.** `PathAwareThrottlerGuard` extends `ThrottlerGuard`. `getTracker()` retorna `{namespace}:{ip}` (namespace = `auth` para rotas `/api/v1/auth/*` ou `/auth/*`, `default` caso contrário). `handleRequest()` aplica limite reduzido (10) em rotas auth, mantendo 100 nas demais. `throwThrottlingException()` lança `HttpException` 429 com payload `{ error: { code: "TOO_MANY_REQUESTS", message, status, timestamp } }`. |
| `backend/gateway/src/app.module.ts` | `ThrottlerModule.forRoot([{name:'default', ttl:60000, limit:100}, {name:'auth', ttl:60000, limit:10}])` e `APP_GUARD` global apontando para `PathAwareThrottlerGuard`. |

### Verificação

```
# 10 primeiras requests → 401 (credencial inválida, esperado)
# 11ª em diante → 429
$ for i in $(seq 1 12); do curl ... /api/v1/auth/login; done
```

Resposta 429:
```json
{
  "error": {
    "code": "TOO_MANY_REQUESTS",
    "message": "Muitas requisições em pouco tempo. Aguarde antes de tentar novamente.",
    "status": 429,
    "timestamp": "2026-06-08T17:58:17.881Z"
  }
}
```

---

## 8. Resumo arquivos novos / alterados

### Backend (NestJS)

```
backend/docker-compose.yml                                          [editado]
backend/package-lock.json                                           [regenerado]
backend/profile-service/package.json                                [editado]
backend/profile-service/src/main.ts                                 [editado]
backend/profile-service/src/profile/profile.controller.ts          [editado]
backend/profile-service/src/profile/profile.module.ts              [editado]
backend/profile-service/src/profile/profile.service.ts             [editado]
backend/profile-service/src/profile/s3.service.ts                  [NOVO]
backend/gateway/src/app.module.ts                                   [editado]
backend/gateway/src/throttling/path-aware-throttler.guard.ts       [NOVO]
```

### Mobile (Flutter)

```
pubspec.yaml                                                        [editado]
lib/app.dart                                                        [editado]
lib/core/config/app_config.dart                                     [editado]
lib/core/router/app_router.dart                                     [editado]
lib/data/repositories/auth_repository_impl.dart                     [editado]
lib/data/repositories/profile_repository_impl.dart                  [editado]
lib/domain/repositories/profile_repository.dart                     [editado]
lib/presentation/auth/screens/login_screen.dart                     [reescrito]
lib/presentation/auth/screens/register_screen.dart                  [reescrito]
lib/presentation/onboarding/screens/welcome_screen.dart             [reescrito]
lib/presentation/profile/notifiers/profile_notifier.dart            [editado]
lib/presentation/profile/screens/my_profile_screen.dart             [editado]
lib/presentation/profile/screens/user_profile_screen.dart           [editado]
```

### Docs

```
docs/mvp/status-implementacao.md                                    [atualizado]
docs/walkthrough-sessao.md                                          [NOVO — este documento]
```

### Configurações do ambiente

```
C:\Users\USER\.android\avd\flutter_emulator.avd\config.ini          [hw.keyboard=yes]
```

---

## 9. Como rodar tudo agora

```bash
# Pasta backend/
docker compose up -d --build      # 8 containers: postgres, redis, minio, gateway + 4 serviços

# Pasta raiz do projeto
flutter pub get
flutter run -d web-server \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=WS_BASE_URL=http://localhost:3004 \
  --dart-define=PROFILE_DIRECT_URL=http://localhost:3002 \
  --web-port=8090 --web-hostname=localhost
```

Acesse http://localhost:8090.

| Endpoint útil | URL |
|---|---|
| Gateway | http://localhost:3000/api/v1 |
| MinIO Console | http://localhost:9001 (minioadmin / minioadmin) |
| Postgres | localhost:5432 (interaedu / interaedu_dev_password) |
| Redis | localhost:6379 |

---

## 10. B-03 — Login com Google OAuth

Implementação completa do **back-end + front-end web**. Requer apenas que o operador crie um OAuth Client ID no Google Cloud Console e configure duas chaves para ativar.

### Modelagem de dados

| Arquivo | Mudança |
|---|---|
| `backend/auth-service/src/database/entities/user-credential.entity.ts` | `passwordHash` virou nullable (contas só-OAuth não têm senha local). Coluna nova `googleId` (varchar(64), nullable, unique). Como `synchronize=true` em dev, a coluna é criada automaticamente no postgres ao subir o auth-service. |

### Backend

| Arquivo | Mudança |
|---|---|
| `backend/auth-service/package.json` | + `google-auth-library` ^9.10.0 (verifica ID tokens com as chaves públicas do Google). |
| `backend/auth-service/src/auth/google-auth.service.ts` | **Novo.** `GoogleAuthService.loginWithGoogle(idToken)` verifica audience contra `GOOGLE_CLIENT_ID`, extrai email/sub/email_verified, valida domínio contra `InstitutionService.findByEmailDomain()`, busca user por `googleId` ou `email`, vincula ou cria, publica `user.registered` no Redis se for novo, devolve par de JWT (mesma estrutura do login local). Se `GOOGLE_CLIENT_ID` não estiver setado, throw `ServiceUnavailableException` → 503 com formato canônico. |
| `backend/auth-service/src/auth/dto/google-login.dto.ts` | **Novo.** DTO com `id_token: string` (class-validator). |
| `backend/auth-service/src/auth/auth.controller.ts` | + `POST /auth/google` (público) delegando para `GoogleAuthService`. |
| `backend/auth-service/src/auth/auth.module.ts` | + `GoogleAuthService` como provider. |
| `backend/auth-service/src/auth/auth.service.ts` | `login()` ajustado para tratar `passwordHash === null` — retorna mensagem orientando o usuário a usar "Continuar com Google". |
| `backend/docker-compose.yml` | + `GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID:-}` no auth-service. Lê de `.env` ou do shell. Vazio é OK — endpoint só fica indisponível. |
| `backend/package-lock.json` | Regenerado para incluir `google-auth-library` na cadeia transitiva. |

### Frontend (web)

| Arquivo | Mudança |
|---|---|
| `web/index.html` | + `<meta name="google-signin-client_id" content="">` (placeholder a ser preenchido pelo operador). + tag `<script src="https://accounts.google.com/gsi/client" async defer>`. + função JS global `window.interaeduGoogleSignIn()` que inicializa GIS, faz `prompt()` e devolve uma `Promise<credential>`. Erros são sinalizados como `NOT_CONFIGURED` (meta vazio) ou `USER_DISMISSED` (popup fechado). |
| `lib/core/auth/google_sign_in_web.dart` | **Novo.** Ponte Dart→JS via `dart:js_interop`. `fetchGoogleIdToken()` aguarda a Promise e devolve `Future<String>` com o ID token. Lança `GoogleSignInNotConfigured` ou `GoogleSignInCancelled` (typed errors). |
| `lib/domain/repositories/auth_repository.dart` | + `Future<void> loginWithGoogleIdToken(String idToken)`. |
| `lib/data/repositories/auth_repository_impl.dart` | + `loginWithGoogleIdToken` faz `POST /auth/google` com `{ id_token }` e grava o par de tokens no `SecureStorage`. |
| `lib/core/auth/auth_notifier.dart` | + `loginWithGoogleIdToken(idToken)` que delega ao repo e atualiza `AuthStatus`. |
| `lib/core/network/api_endpoints.dart` | + `static const String google = '/auth/google';` |
| `lib/presentation/auth/screens/login_screen.dart` | Botão "Continuar com Google" passou de `onPressed: () {}` (visual) para `_handleGoogleSignIn`: chama `fetchGoogleIdToken()`, depois `AuthNotifier.loginWithGoogleIdToken(idToken)`. Spinner + texto "Conectando..." enquanto roda. Tratamento amigável das exceptions tipadas. Em plataformas que não são web (`kIsWeb == false`) mostra um aviso. |

### Como ativar (operador)

1. Em [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials), criar um **OAuth 2.0 Client ID** do tipo **Web application**.
2. Em **Authorized JavaScript origins**, adicionar `http://localhost:8090` (ou o host efetivo do app).
3. Copiar o Client ID gerado e colá-lo em **dois lugares**:
   - `web/index.html`: `<meta name="google-signin-client_id" content="SEU_CLIENT_ID.apps.googleusercontent.com">`
   - Variável de ambiente `GOOGLE_CLIENT_ID` antes de subir o auth-service (ex.: arquivo `backend/.env` ou export no shell).
4. `cd backend && docker compose up -d --build auth-service` para o backend pegar o novo env.
5. Recarregar o app web. O botão "Continuar com Google" passa a abrir o popup do Google. Domínios fora das instituições aprovadas continuam sendo rejeitados pelo backend.

### Como o backend devolve quando não está configurado

```http
POST /api/v1/auth/google
{ "id_token": "..." }

HTTP/1.1 503 Service Unavailable
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Login com Google não está configurado neste ambiente.",
    "status": 503,
    "timestamp": "..."
  }
}
```

O front-end traduz isso para um SnackBar orientando o passo a passo.

---

## 11. Multipart proxying no gateway (eliminando bypass de B-02)

A solução pragmática original do B-02 era pular o gateway e atacar `localhost:3002` direto, porque o `ProxyService` baseado em axios não consegue encaminhar `multipart/form-data` (o body-parser nunca toca em multipart, mas o controller envia `req.body` vazio para o downstream).

**Solução adotada:** middleware Express puro registrado em `main.ts` *antes* do roteador NestJS.

| Arquivo | Mudança |
|---|---|
| `backend/gateway/src/proxy/multipart-proxy.middleware.ts` | **Novo.** Função `createMultipartProxy(urls)` devolve middleware Express. Detecta `Content-Type` começando com `multipart/`, resolve serviço pelo path (mesma tabela do `ProxyController`), abre `http.request` para o upstream e pipea `req → upstreamReq` e `upstreamRes → res`. Headers (incluindo o boundary do multipart) são propagados intactos; apenas `host` é reescrito para o upstream. Falhas viram 502 no formato canônico. |
| `backend/gateway/src/main.ts` | `app.use(createMultipartProxy(...))` instalado antes de `setGlobalPrefix`, garantindo que o stream chegue intacto. |
| `lib/data/repositories/profile_repository_impl.dart` | URL do avatar voltou a usar `AppConfig.apiBaseUrl` (gateway), eliminando o bypass. |
| `lib/core/config/app_config.dart` | Removida constante `profileDirectUrl` (não usada mais). |

**Validação:**
```
$ curl -X POST http://localhost:3000/api/v1/users/me/avatar -H "Authorization: Bearer ..." -F "file=@test.png"
{"avatar_url":"http://localhost:9000/interaedu/avatars/<userId>/<uuid>.png"}
HTTP 201
```

Multipart agora trafega via gateway → profile-service. Rate limit (path-aware) e logs centralizados continuam funcionando.

---

## 12. Observabilidade (Prometheus + Grafana) — B-06

Stack completa no compose, com Gateway expondo `/metrics` em formato Prometheus e Grafana auto-provisionado.

### Backend (gateway)

| Arquivo | Mudança |
|---|---|
| `backend/gateway/package.json` | + `@willsoto/nestjs-prometheus` ^6.0.0, `prom-client` ^15.0.0 |
| `backend/gateway/src/metrics/metrics.module.ts` | **Novo.** `PrometheusModule` (defaultMetrics on) + provider `http_request_duration_seconds` (Histogram, labels: method/route/status_code, buckets 10ms→10s). |
| `backend/gateway/src/metrics/metrics.middleware.ts` | **Novo.** Mede `hrtime.bigint()` no início e finaliza no `res.on('finish')`. Sanitiza route (UUID/inteiro → `:id`) pra controlar cardinalidade. Ignora `/metrics` para não inflar contadores. |
| `backend/gateway/src/app.module.ts` | + import do `MetricsModule`; `configure()` registra `MetricsMiddleware` em `'*'`. |

### Infra (Docker Compose)

| Arquivo | Mudança |
|---|---|
| `backend/docker-compose.yml` | + serviços `prometheus` (porta 9090) e `grafana` (porta 3030 → 3000 interno). Grafana com `GF_AUTH_ANONYMOUS_ENABLED=true` para acesso somente leitura sem login. Volumes `prometheus_data`, `grafana_data`. |
| `backend/observability/prometheus.yml` | **Novo.** Scrape config — `gateway:3000/api/v1/metrics` (15s interval). Pronto para receber novos jobs (auth, profile, etc.) à medida que instrumentação for adicionada. |
| `backend/observability/grafana/provisioning/datasources/datasource.yml` | **Novo.** Datasource `Prometheus` apontando para `http://prometheus:9090`, default. |
| `backend/observability/grafana/provisioning/dashboards/dashboards.yml` | **Novo.** Provider que carrega JSONs de `/var/lib/grafana/dashboards`. |
| `backend/observability/grafana/dashboards/gateway-saude.json` | **Novo.** Dashboard inicial "InteraEdu — Saúde do Gateway" com 4 painéis: req/s por status, latência p50/p95/p99, taxa de erro 5xx (stat), throughput por método. |

### Como acessar

| Recurso | URL |
|---|---|
| Prometheus | http://localhost:9090 |
| Métricas raw | http://localhost:3000/api/v1/metrics |
| Grafana | http://localhost:3030 (login `admin/admin` ou visualização anônima) |
| Dashboard | http://localhost:3030/d/interaedu-gateway/interaedu-saude-do-gateway |

### Roadmap de instrumentação

Para expandir, basta replicar o `MetricsModule` + `MetricsMiddleware` nos demais serviços NestJS e adicionar o respectivo job em `prometheus.yml`. As métricas que o roadmap (`docs/arquitetura/devops.md §5.1`) lista — `auth_login_attempts_total`, `feed_cache_hits_total`, `active_websocket_connections` etc. — são contadores/gauges adicionais que cada serviço cria localmente.

---

## 13. Seed de dados de demonstração + polish visual

Em preparação à apresentação, fizemos um sprint focado em "viabilidade de demo".

### Seed

`backend/scripts/seed-demo.sql` — populando 5 usuários demo (`ana@aluno.ufmg.br`, `pedro@aluno.ufmg.br`, `julia@ufmg.br`, `carla@usp.br`, `lucas@alumni.usp.br`), todos com senha `Demo@1234`, perfis completos (nome, bio, curso, período, avatar pravatar, skills), 9 posts (mix local/global com conteúdo crível), 5 conexões aceitas + 2 pedidos pendentes para `joao`. Idempotente (ON CONFLICT / DELETE+INSERT). Para rodar:

```
cat backend/scripts/seed-demo.sql | docker exec -i interaedu-postgres psql -U interaedu -d interaedu
```

### Polish visual de telas demo

| Tela | Mudança |
|---|---|
| `lib/presentation/messages/screens/chat_room_screen.dart` | Reescrita com `glassAppBar`, avatar+nome no header, indicador WebSocket "Conectado em tempo real" reativo via `Consumer<SocketService>`, empty state com ícone `waving_hand`, composer com pílula arredondada e botão circular gradiente. |
| `lib/presentation/profile/screens/user_profile_screen.dart` | `glassAppBar` no lugar da AppBar default; padding ajustado para conteúdo respeitar a área transparente. |
| `lib/presentation/profile/screens/connections_screen.dart` | `glassAppBar` com `TabBar` estilizado (primary color, indicator weight 3). |
| `lib/presentation/auth/screens/login_screen.dart` | Bloco "OU / Continuar com Google" escondido atrás do const `_showGoogleSignIn = false`. Evita SnackBar de "GOOGLE_CLIENT_ID não configurado" durante a demo. Re-ativação: flipar o const + configurar GIS (ver §10). |

### Roteiro de demo recomendado (5 min)

1. Login com `joao@ufmg.br` (sua senha) → vai pro Feed populado
2. Feed Local (posts UFMG) → trocar pra Global (posts USP aparecem)
3. Reagir + comentar em algum post (Profa. Júlia ou Carla são bons gatilhos)
4. Aba Perfil: ver avatar, skills, clicar no avatar e upload uma imagem nova
5. Aba Buscar: digitar "Carla" → ver perfil → clicar "Mensagem" → chat abre
6. Mandar uma mensagem
7. Em outra janela anônima: login `carla@usp.br` / `Demo@1234` → ver chat e mensagem em tempo real
8. (Técnico, opcional) http://localhost:3030 — dashboard Grafana
9. (Técnico, opcional) http://localhost:9001 — MinIO com avatar uploadado

---

## 14. Estado final do MVP

- ✅ M-01 a M-08 (mobile) — completos
- ✅ B-01, B-02, B-04, B-05, B-06 (backend) — completos
- ✅ B-03 código pronto, ativação requer credencial Google Cloud do operador
- ✅ Gateway com proxy multipart correto (sem mais bypass do `localhost:3002`)
- ✅ Observabilidade básica (Prometheus + Grafana com dashboard de gateway)

Próximas frentes (pós-MVP):
- Instrumentar `auth-service`, `profile-service`, `feed-service`, `messaging-service` com `/metrics`
- Dashboards adicionais (Auth, Feed, Mensageria, Conexões PostgreSQL)
- Tracing distribuído (OpenTelemetry + Jaeger)
- Logs estruturados em JSON via Pino
- FCM push notifications
- Deploy cloud + CI/CD
