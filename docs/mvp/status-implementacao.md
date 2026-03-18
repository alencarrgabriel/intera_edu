# Status de Implementação MVP — InteraEdu

**Versão:** 2.0 | **Data:** Março 2026

Este documento acompanha o progresso técnico do MVP do InteraEdu — a rede social acadêmica restrita. O app mobile é desenvolvido em Flutter e o backend opera como microsserviços em NestJS.

---

## 1. Status das Funcionalidades

| Funcionalidade | Backend | Mobile | Status |
|---|---|---|---|
| Registro com e-mail + OTP | ✅ Completo | ✅ Telas implementadas | ✅ Pronto |
| Login com JWT | ✅ Completo | ✅ Tela implementada | ✅ Pronto |
| Refresh token (rotação) | ✅ Completo | ❌ Não implementado | ⚠️ Parcial |
| Logout | ✅ Completo | ❌ Sem botão/fluxo | ⚠️ Parcial |
| Feed local (mesma instituição) | ✅ Completo | ✅ Tela implementada | ✅ Pronto |
| Feed global (entre instituições) | ✅ Completo | ❌ Sem seletor de scope | ⚠️ Parcial |
| Criar post (texto) | ✅ Completo | ❌ Sem formulário | ❌ Falta |
| Ver post individual | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Deletar próprio post | ✅ Completo | ❌ Sem UI | ❌ Falta |
| Reagir a post | ✅ Completo | ❌ Sem botões | ❌ Falta |
| Comentar em post | ✅ Completo | ❌ Sem UI | ❌ Falta |
| Ver meu perfil | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Editar perfil | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Buscar usuários | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Ver perfil de outro usuário | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Enviar solicitação de conexão | ✅ (estrutura) | ❌ Sem UI | ❌ Falta |
| Aceitar/rejeitar conexão | ✅ (estrutura) | ❌ Sem UI | ❌ Falta |
| Listar chats | ✅ Completo | ❌ Sem tela | ❌ Falta |
| Chat em tempo real (WebSocket) | ✅ Completo | ❌ Sem implementação | ❌ Falta |

---

## 2. O que falta para o MVP estar completo

### Mobile (prioridade alta):
1. Interceptor de refresh automático de token no `ApiClient` (tarefa **M-02**)
2. Gerenciamento de estado de autenticação global — `Provider` ou `Riverpod` (tarefa **M-01**)
3. Tela de criação de post com seletor de scope local/global (tarefa **M-03**)
4. Botões de reação e comentários no feed (tarefa **M-04**)
5. Tela de perfil próprio e edição (tarefa **M-05**)
6. Tela de busca de usuários e visualização de perfil externo (tarefa **M-06**)
7. Telas de conexões (listar + solicitações pendentes)
8. Fluxo de logout (tarefa **M-08**)
9. Telas de chat + WebSocket (tarefa **M-07**)

### Backend (ajustes pendentes):
1. Endpoint `POST /auth/google` — OAuth com Google (previsto no SRS, tarefa **B-03**)
2. `profile-service`: criar perfil automaticamente ao receber evento `user.registered` (tarefa **B-01**)
3. Upload de avatar via MinIO (tarefa **B-02**)
4. `messaging-service`: validar integração WebSocket end-to-end

> Para detalhes de implementação de cada tarefa, consulte [`docs/guias/tarefas-ia.md`](../guias/tarefas-ia.md).

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
| **M1 — Auth Completo** | Login, registro, OTP, refresh e logout funcionando de ponta a ponta |
| **M2 — Feed Funcional** | Criar, ver, reagir e comentar posts no app |
| **M3 — Perfis Completos** | Editar perfil, buscar usuários, conectar com outros |
| **M4 — MVP Pronto** | Todos os fluxos principais operacionais sem erros críticos |
| **M5 — Chat** | Mensagens em tempo real funcionando |
| **M6 — Produção** | Deploy em nuvem, CI/CD, monitoramento |
