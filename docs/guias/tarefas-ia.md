# Tarefas para Execução por IA — InteraEdu

> Este arquivo lista tarefas granulares, objetivas e com contexto suficiente para que outra IA (ou desenvolvedor) possa executá-las sem ambiguidade. Cada tarefa inclui contexto, dependências e resultado esperado.

---

## CONVENÇÕES OBRIGATÓRIAS ANTES DE IMPLEMENTAR

- Backend: NestJS + TypeScript + TypeORM + PostgreSQL.
- Mobile: Flutter + Dart (Clean Architecture: `core/data/domain/presentation`).
- Todos os endpoints passam pelo Gateway em `/api/v1`.
- JWT: access token 15min, refresh token 7d com rotação.
- Erros: `{ "error": { "code": "SNAKE_CASE", "message": "..." } }`.
- Paginação: cursor base64 de `{ t: ISO_DATE_STRING }`.
- Nunca duplicar lógica entre serviços — usar `@interaedu/shared`.

---

## BACKEND

### B-01 — Criar perfil automaticamente ao receber o evento `user.registered`

**Contexto:** O auth-service publica `user.registered` no canal Redis `interaedu.events` após o registro. O profile-service deve escutar e criar o `UserProfile` inicial.

**Arquivo a criar:** `backend/profile-service/src/events/user-events.subscriber.ts`

**O que fazer:**
1. Injetar `RedisService` do `@interaedu/shared`.
2. No `onModuleInit()`, subscrever ao canal `interaedu.events`.
3. Filtrar mensagens do tipo `user.registered`.
4. Criar `UserProfile` com `id = payload.userId`, `institutionId = payload.institutionId`, `privacyLevel = 'local_only'`.
5. Tratar duplicatas com idempotência — não lançar exceção se o perfil já existir.

**Dependências:** Entidade `UserProfile` em `profile-service/src/database/entities/`, `RedisService` já disponível.

**Resultado esperado:** Após o registro, um perfil vazio é criado automaticamente sem intervenção manual.

---

### B-02 — Endpoint de upload de avatar (MinIO)

**Contexto:** O `profile-service` precisa aceitar upload de avatar e retornar a URL pública do MinIO.

**Arquivo a criar:** `backend/profile-service/src/profile/upload.controller.ts`

**O que fazer:**
1. Criar endpoint `POST /users/me/avatar` aceitando `multipart/form-data`.
2. Validar que o arquivo é uma imagem (MIME: `image/jpeg`, `image/png`, `image/webp`).
3. Limitar o tamanho a 5MB.
4. Fazer upload para o MinIO no bucket `interaedu`, caminho `avatars/{userId}/{uuid}.{ext}`.
5. Salvar a URL pública em `UserProfile.avatarUrl`.
6. Retornar `{ "avatar_url": "..." }`.

**Dependências:** AWS SDK (`@aws-sdk/client-s3`), variáveis `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`.

**Resultado esperado:** O mobile consegue fazer upload do avatar e receber a URL para exibição.

---

### B-03 — OAuth com Google (auth-service)

**Contexto:** O SRS prevê login com Google. O e-mail do Google deve ser validado contra a tabela de instituições (mesmo domínio).

**Arquivo a criar:** `backend/auth-service/src/auth/google-auth.strategy.ts`

**O que fazer:**
1. Instalar `passport-google-oauth20` e `@nestjs/passport`.
2. Criar `GoogleStrategy` com `clientID`, `clientSecret` e `callbackURL` vindos de variáveis de ambiente.
3. No callback, validar domínio do e-mail contra `InstitutionService.findByEmailDomain()`.
4. Se domínio não aprovado: retornar erro 403.
5. Se aprovado: criar ou buscar `UserCredential` com `googleId`, sem senha.
6. Emitir `user.registered` se for novo usuário.
7. Retornar `access_token` + `refresh_token`.

**Resultado esperado:** Endpoint `POST /auth/google` (ou callback OAuth) funcionando.

---

### B-04 — Sistema de conexões completo (profile-service)

**Contexto:** A entidade `Connection` já existe com os estados `pending/accepted/rejected`. Faltam os endpoints REST.

**Arquivo a verificar/criar:** `backend/profile-service/src/connections/connections.controller.ts`

**O que fazer:**
1. `POST /connections` — enviar solicitação `{ addressee_id: uuid }`.
2. `GET /connections` — listar conexões aceitas do usuário autenticado.
3. `GET /connections/requests` — listar solicitações pendentes recebidas.
4. `PATCH /connections/:id` — aceitar ou rejeitar `{ action: 'accept' | 'reject' }`.
5. `DELETE /connections/:id` — desfazer conexão aceita.
6. Validar que não há solicitação duplicada (usar `ConflictException`).

**Resultado esperado:** CRUD completo de conexões entre usuários.

---

### B-05 — Rate limiting no gateway

**Contexto:** O gateway não tem rate limiting. Em produção, é crítico para segurança.

**O que fazer:**
1. Instalar `@nestjs/throttler`.
2. Configurar `ThrottlerModule` no `gateway/src/app.module.ts`.
3. Limite padrão: 100 req/min por IP.
4. Limite mais restrito para `/auth/**`: 10 req/min por IP.
5. Retornar erro 429 com `{ error: { code: "TOO_MANY_REQUESTS", ... } }`.

---

## MOBILE (FLUTTER)

### M-01 — Gerenciamento de estado de autenticação global

**Contexto:** Não há gerenciamento de estado global. Screens fazem chamadas diretas aos repositórios sem coordenação central de autenticação.

**Pacote a usar:** `provider` ou `flutter_riverpod` (adicionar ao `pubspec.yaml`).

**Arquivos a criar:** `lib/core/auth/auth_state.dart` e `lib/core/auth/auth_notifier.dart`

**O que fazer:**
1. Criar `AuthState` com estados: `unauthenticated`, `authenticated(user)`, `loading`.
2. Criar `AuthNotifier` (ChangeNotifier ou StateNotifier) que:
   - No startup: verifica `SecureStorage` por tokens existentes.
   - Se access token presente: vai para `authenticated`.
   - Se apenas refresh token: tenta renovar e vai para `authenticated` ou `unauthenticated`.
   - Método `login(email, password)` → chama `AuthRepository.login()` → salva tokens → estado `authenticated`.
   - Método `logout()` → chama `AuthRepository.logout()` → limpa tokens → estado `unauthenticated`.
3. Envolver `MaterialApp` com `ChangeNotifierProvider<AuthNotifier>`.
4. `app.dart` observa `AuthState` para definir a rota inicial.

**Resultado esperado:** App redireciona automaticamente para login/feed baseado no estado de autenticação.

---

### M-02 — Refresh automático de token no ApiClient

**Contexto:** `ApiClient` em `lib/core/network/api_client.dart` não tenta renovar o token expirado. Quando o access token expira, o usuário vê erro.

**O que fazer:**
1. Adicionar método privado `_refreshIfNeeded()` no `ApiClient`.
2. Quando `_handleResponse()` receber status 401:
   - a. Tentar `POST /auth/refresh` com o refresh token do `SecureStorage`.
   - b. Se sucesso: salvar novos tokens e retentar a requisição original.
   - c. Se falha (refresh também expirado): chamar `AuthNotifier.logout()` → redirecionar para login.
3. Usar um flag `_isRefreshing` para evitar múltiplas renovações simultâneas.

**Dependências:** M-01 deve estar implementado primeiro.

**Resultado esperado:** O usuário nunca vê erro de token expirado; o app renova automaticamente.

---

### M-03 — Tela de criação de post

**Contexto:** O feed-service tem `POST /posts` pronto. O mobile não tem UI para criar posts.

**Arquivo a criar:** `lib/presentation/feed/screens/create_post_screen.dart`

**O que fazer:**
1. Campo de texto `content` (máx 1000 caracteres, contador visível).
2. Seletor de scope: "Local" (apenas minha instituição) / "Global".
3. Botão "Publicar" que chama `FeedRepository.createPost()`.
4. Estado de loading no botão durante o envio.
5. Ao sucesso: voltar para `FeedScreen` e recarregar o feed.
6. Tratar erros com `SnackBar`.
7. Adicionar botão FAB ou "+" na `FeedScreen` para navegar para esta tela.

**Resultado esperado:** O usuário consegue criar posts diretamente no app.

---

### M-04 — Botões de reação e comentários no feed

**Contexto:** Posts no feed exibem `reaction_count` e `comment_count` mas sem interação.

**O que fazer em `feed_screen.dart` e/ou widget `PostCard`:**
1. Criar widget `PostCard` separado em `lib/presentation/feed/widgets/post_card.dart`.
2. Botão de reação "👍 Curtir" → `POST /posts/{id}/reactions { type: 'like' }`.
3. Estado local: incrementar contador otimisticamente ao tocar.
4. Botão "💬 Comentar" → abrir modal/bottom sheet com lista de comentários + campo de texto.
5. Envio de comentário → `POST /posts/{id}/comments { content: "..." }`.

**Resultado esperado:** Feed totalmente interativo com reações e comentários.

---

### M-05 — Tela de perfil próprio e edição

**Contexto:** Backend tem `GET /users/me` e `PATCH /users/me` prontos.

**Arquivos a criar:**
- `lib/presentation/profile/screens/my_profile_screen.dart`
- `lib/presentation/profile/screens/edit_profile_screen.dart`

**O que fazer (my_profile_screen.dart):**
1. `GET /users/me` ao carregar.
2. Exibir: avatar, nome completo, bio, curso, período, habilidades, links, instituição.
3. Botão "Editar perfil" → navegar para `EditProfileScreen`.

**O que fazer (edit_profile_screen.dart):**
1. Campos: nome, bio, curso, período, nível de privacidade (radio: público/local/privado).
2. Seletor de habilidades (buscar `GET /skills` e marcar selecionadas).
3. Salvar → `PATCH /users/me` → voltar e atualizar tela de perfil.

---

### M-06 — Tela de busca de usuários e visualização de perfil externo

**Arquivos a criar:**
- `lib/presentation/profile/screens/search_screen.dart`
- `lib/presentation/profile/screens/user_profile_screen.dart`

**O que fazer (search_screen.dart):**
1. Campo de busca com debounce de 300ms.
2. Chamar `GET /users/search?q={query}`.
3. Exibir lista de `ProfileCard` (avatar, nome, curso, instituição).
4. Ao tocar → navegar para `UserProfileScreen`.

**O que fazer (user_profile_screen.dart):**
1. `GET /users/{id}` com tratamento de perfil privado (404 quando sem acesso).
2. Exibir dados públicos do perfil.
3. Botão "Conectar" → `POST /connections { addressee_id: id }`.

---

### M-07 — Telas de chat e WebSocket

**Contexto:** O messaging-service tem chats + WebSocket Gate na porta 3004. Falta integração no mobile.

**Pacote a adicionar:** `web_socket_channel`

**Arquivos a criar:**
- `lib/presentation/messaging/screens/chats_list_screen.dart`
- `lib/presentation/messaging/screens/chat_screen.dart`
- `lib/core/websocket/websocket_service.dart`

**O que fazer:**
1. `WebSocketService`: conectar a `ws://localhost:3004` com `Authorization: Bearer {token}` no handshake.
2. `ChatsListScreen`: `GET /chats` → listar conversas com preview da última mensagem.
3. `ChatScreen`: carregar histórico via `GET /chats/{id}/messages` + conectar WebSocket.
4. Enviar mensagem via WebSocket: `{ type: 'message', chatId, content }`.
5. Receber mensagens em tempo real e adicionar na lista local.

---

### M-08 — Fluxo de logout

**O que fazer:**
1. Adicionar opção "Sair" (menu ou drawer).
2. Chamar `POST /auth/logout { refresh_token }` para invalidar o token no servidor.
3. Limpar tokens no `SecureStorage`.
4. Chamar `AuthNotifier.logout()` → redirecionar para `LoginScreen`.

**Dependência:** M-01 necessário.

---

## DEPENDÊNCIAS ENTRE TAREFAS

```
M-01 (AuthState) → M-02 (Refresh Token) → todos os outros M-*
M-03 (Criar post) → independente após M-01
M-04 (Reações) → independente após M-01
M-05 (Perfil) → independente após M-01
M-06 (Busca) → independente após M-01
M-07 (Chat) → independente após M-01, porém mais complexo
M-08 (Logout) → depende de M-01
B-01 (Perfil auto) → deve rodar antes de M-05 funcionar corretamente
B-02 (Upload avatar) → pode ser feito em paralelo com M-05
```
