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

## 10. Próxima etapa

**B-03 — Login com Google OAuth.** Veja a seção implementação nas seções subsequentes deste walkthrough quando concluída.
