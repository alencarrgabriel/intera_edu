# Status de Implementação MVP — InteraEdu

**Versão:** 2.1 | **Data:** Junho 2026

Este documento acompanha o progresso técnico do MVP do InteraEdu — a rede social acadêmica restrita. O app mobile é desenvolvido em Flutter e o backend opera como microsserviços em NestJS.

---

## 1. Status das Funcionalidades

| Funcionalidade | Backend | Mobile | Status |
|---|---|---|---|
| Registro com e-mail + OTP | ✅ Completo | ✅ Telas traduzidas e completas | ✅ Pronto |
| Login com JWT | ✅ Completo | ✅ Tela implementada e integrada | ✅ Pronto |
| Refresh token | ✅ Completo | ✅ Interceptor ApiClient ativo | ✅ Pronto |
| Logout | ✅ Completo | ✅ Botão no Feed + Dialog | ✅ Pronto |
| Feed local (mesma instituição) | ✅ Completo | ✅ Tela e scroll infinito | ✅ Pronto |
| Feed global (entre instituições) | ✅ Completo | ✅ SegmentedButton de filtro | ✅ Pronto |
| Criar post (texto) | ✅ Completo | ✅ CreatePostScreen | ✅ Pronto |
| Ver post individual | ✅ Completo | ✅ Exibição no PostCard | ✅ Pronto |
| Deletar próprio post | ✅ Completo | ✅ Via API integrada | ✅ Pronto |
| Reagir a post | ✅ Completo | ✅ Atualização Otimista | ✅ Pronto |
| Comentar em post | ✅ Completo | ✅ CommentsSheet | ✅ Pronto |
| Ver meu perfil | ✅ Completo | ✅ MyProfileScreen | ✅ Pronto |
| Editar perfil | ✅ Completo | ✅ EditProfileScreen c/ Chips | ✅ Pronto |
| **Upload de avatar (MinIO)** | ✅ Completo | ✅ FilePicker + spinner | ✅ Pronto |
| Buscar usuários | ✅ Completo | ✅ SearchScreen c/ Debounce | ✅ Pronto |
| Ver perfil de outro usuário | ✅ Completo | ✅ UserProfileScreen restrito | ✅ Pronto |
| Enviar/Aceitar/Rejeitar conexão | ✅ Completo | ✅ ConnectionsScreen abas | ✅ Pronto |
| **Iniciar chat direto a partir do perfil** | ✅ Completo | ✅ Botão "Mensagem" no UserProfileScreen | ✅ Pronto |
| Listar chats | ✅ Completo | ✅ ChatsListScreen | ✅ Pronto |
| **Chat em tempo real (WebSocket)** | ✅ Completo | ✅ SocketService auto-conecta após login | ✅ Pronto |
| **Rate limiting no gateway** | ✅ Completo (100/min default, 10/min /auth) | — | ✅ Pronto |
| **Proxy multipart no gateway** | ✅ Stream raw via middleware Express | — | ✅ Pronto |
| **Observabilidade (Prometheus + Grafana)** | ✅ Gateway /metrics + dashboard inicial | — | ✅ Pronto (parcial — restantes serviços a instrumentar) |
| **Login com Google OAuth** | ✅ Endpoint /auth/google verificando ID token | ✅ Botão funcional via GIS web | ⏳ Aguardando credencial Google Cloud do operador |

---

## 2. O que falta para o MVP estar completo

> **MVP funcionalmente completo.** Os fluxos principais do produto (auth → feed → perfil → conexões → chat em tempo real) estão operacionais ponta a ponta com backend Docker rodando.

### Concluído na rodada de "sprint de funcionalidades" (Jun 2026):

| ID | Funcionalidade | Status |
|---|---|---|
| **RF-06** | Esqueci minha senha (OTP + redefinir) | ✅ Backend + Frontend (tela `ForgotPasswordScreen`) |
| **RF-15** | Bloquear usuário | ✅ Tabela `profile.user_blocks` + endpoints `/users/me/blocks` + menu 3-dots no perfil |
| **RF-21** | Reações `curtir`, `perspicaz`, `apoio` | ✅ Long-press abre `_ReactionPicker` com as 3 opções |
| **RF-22** | Respostas aninhadas (1 nível) em comentários | ✅ CommentsSheet agrupa por `parent_comment_id`, exibe replies indentadas + "Responder" |
| **RF-24** | Criar grupo de estudos (≤50 membros) | ✅ Tela `CreateGroupScreen` lista conexões aceitas + nome do grupo |
| **RF-25** | Mensagens em grupo | ✅ Backend valida membro; UI reusa `ChatRoomScreen` |
| **RF-27** | Arquivos em chat (PDF/imagem ≤10MB) | ✅ `S3Service` no messaging + endpoint multipart + `FilePicker` no composer + `_AttachmentChip` renderiza imagem ou ícone PDF |
| **RF-35** | Central de notificações in-app | ✅ Tabela `messaging.notifications` + endpoints + tela `NotificationsScreen` (sino abre lista) |
| **RF-37** | Cadastro de IES (admin) | ✅ Endpoint `POST /institutions` (role check inline) |
| **RF-38** | Gerenciamento de domínios (admin) | ✅ `PATCH /institutions/:id/domains` (add/remove) + cache invalidation |
| **RF-39** | Fila de moderação de denúncias | ✅ `GET /reports` lista abertas, `PATCH /reports/:id` resolve/descarta |
| **RF-40** | Botão "Denunciar" no Feed e Perfil | ✅ Menu 3-dots do post e no perfil de outro usuário → `POST /reports` |

### Pendente (não-bloqueante):
1. ⏳ **B-03 — Ativação do Login Google** — Código implementado (backend + frontend web). Falta apenas o operador criar o OAuth Client ID no Google Cloud Console e configurar:
   - `web/index.html` → meta `google-signin-client_id`
   - `backend/docker-compose.yml` → env `GOOGLE_CLIENT_ID`
2. ⏳ **RF-34 — Push notifications via Firebase FCM** — Mobile-only por design; web não tem service worker configurado.
3. ⏳ **Admin UI** — Endpoints `/institutions` existem mas não há tela mobile. Em produção uma SPA admin separada faz mais sentido.

### Concluído nesta etapa de desenvolvimento:
- ✅ **B-01** — Perfil criado automaticamente via evento `user.registered`
- ✅ **B-02** — Upload de avatar via MinIO (endpoint `POST /users/me/avatar`)
- ✅ **B-03** — Backend + frontend web do login com Google (aguardando credencial Google Cloud)
- ✅ **B-05** — Rate limiting no gateway com bucket por IP e namespace
- ✅ **M-07** — Telas de chat funcionais + WebSocket conectando após login
- ✅ Skin/tema visual aplicado em welcome/register/login conforme protótipos
- ✅ Mock de devMode no `AuthRepositoryImpl` (toggle em `app_config.dart`)

> Para detalhes de implementação de cada tarefa, consulte [`docs/guias/tarefas-ia.md`](../guias/tarefas-ia.md) e o [Walkthrough da Sessão](../walkthrough-sessao.md).

---

## 3. Funcionalidades Pós-MVP

### Fase 2 — Enriquecimento de Produto

| Funcionalidade | Descrição | Complexidade |
|---|---|---|
| Notificações push | Firebase Cloud Messaging para reações, comentários, conexões | Alta |
| Login com Google OAuth | Alternativa ao e-mail + senha | Média |
| Upload de mídia em posts | Imagens/vídeos via MinIO | Alta |
| Stories/Highlights | Publicações temporárias | Alta |
| Grupos acadêmicos | Comunidades por curso/interesse | Muito Alta |
| Eventos acadêmicos | Criação e RSVP de eventos | Média |
| Busca avançada | Elasticsearch por habilidades, cursos, eventos | Alta |

### Fase 3 — Escalabilidade e Qualidade

| Funcionalidade | Descrição |
|---|---|
| Rate limiting avançado | Por usuário + por IP no gateway |
| Observabilidade | OpenTelemetry + Prometheus + Grafana |
| Testes automatizados | Unitários + Integração + E2E |
| CI/CD | GitHub Actions com deploy automático |
| CDN para mídias | CloudFront na frente do MinIO/S3 |
| Moderação de conteúdo | Detecção automática de spam/ofensas |

---

## 4. Roadmap de Desenvolvimento

### Sprint 1 — Estado de Autenticação e Base Mobile (1-2 semanas)
1. Implementar `AuthNotifier` com Provider ou Riverpod no Flutter (M-01)
2. Interceptor de refresh automático no `ApiClient` (M-02)
3. Fluxo de logout — mobile + invalidar refresh token no backend (M-08)
4. Persistência de sessão entre aberturas do app (re-login automático com refresh válido)

### Sprint 2 — Feed Completo (1-2 semanas)
1. Tela de criação de post (texto + seletor local/global) (M-03)
2. Botões de reação (like, insightful, support) (M-04)
3. Tela de comentários + formulário (M-04)
4. Seletor de feed (local vs global) na `FeedScreen`
5. Paginação por cursor no feed Flutter

### Sprint 3 — Perfis e Conexões (1-2 semanas)
1. Tela de perfil próprio com `GET /users/me` (M-05)
2. Tela de edição de perfil: nome, bio, curso, período, habilidades (M-05)
3. Tela de busca de usuários (M-06)
4. Tela de perfil de outro usuário (M-06)
5. UI de solicitações de conexão: enviar/aceitar/rejeitar

### Sprint 4 — Mensagens (2 semanas)
1. Tela de listagem de chats (M-07)
2. Tela de conversa individual (M-07)
3. Integração WebSocket no Flutter via `web_socket_channel` (M-07)
4. Envio e recebimento de mensagens em tempo real (M-07)

### Sprint 5 — Estabilização e QA (1 semana)
1. Tratamento de erros em todos os fluxos
2. Estados de loading e empty states nas telas
3. Testes manuais de ponta a ponta
4. Ajustes de UX e performance

---

## 5. Paralelismo de Desenvolvimento

```
[Backend: Google OAuth]            ↔  [Mobile: Sprint 1 + Sprint 2]
[Backend: Perfil auto via evento]  ↔  [Mobile: Sprint 3]
[Backend: MinIO upload endpoint]   ↔  [Mobile: Sprint 2 (mídia em posts)]
```

---

## 6. Marcos (Milestones)

| Marco | Critério de Conclusão |
|---|---|
| **M1 — Auth Completo** | ✅ Login, registro, OTP, refresh e logout concluídos |
| **M2 — Feed Funcional** | ✅ Criar, ver, reagir e comentar posts no app |
| **M3 — Perfis Completos** | ✅ Editar perfil, **upload de avatar**, buscar usuários, conectar com outros |
| **M4 — MVP Pronto** | ✅ Todos os fluxos principais operacionais ponta-a-ponta |
| **M5 — Chat** | ✅ Mensagens em tempo real via WebSocket (Socket.IO) |
| **M6 — Hardening** | ⏳ Rate limiting ✅, Google OAuth ⏳, Observabilidade ❌ |
| **M7 — Produção** | ❌ Deploy em nuvem, CI/CD, monitoramento |
