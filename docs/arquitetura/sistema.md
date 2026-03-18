# InteraEdu — Arquitetura do Sistema

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Arquitetura de Alto Nível

```text
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTES                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ App Flutter  │  │  Web App     │  │ Painel Admin │           │
│  │  (Mobile)    │  │  (Futuro)    │  │  (Futuro)    │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │        HTTPS/WSS │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (NestJS)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Limite de│ │ Validador│ │ Roteador │ │ Circuit  │            │
│  │ Taxa     │ │ JWT      │ │          │ │ Breaker  │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
└────────┬──────────┬──────────┬──────────┬───────────────────────┘
         │          │          │          │
    HTTP │     HTTP │     HTTP │     HTTP │
         ▼          ▼          ▼          ▼
  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐
  │ Serviço  ││ Serviço  ││ Serviço  ││ Serviço  │
  │ Auth     ││ Profile  ││ Feed     ││ Messaging│
  │ :3001    ││ :3002    ││ :3003    ││ :3004    │
  └────┬─────┘└────┬─────┘└────┬─────┘└────┬─────┘
       │           │           │           │
       ▼           ▼           ▼           ▼
  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐
  │ auth_db  ││profile_db││ feed_db  ││  msg_db  │
  │(Postgres)││(Postgres)││(Postgres)││(Postgres)│
  └──────────┘└──────────┘└──────────┘└──────────┘
       │           │           │           │
       └───────────┴───────────┴───────────┘
                       │
              ┌────────┴────────┐
              │     Redis       │
              │ (Cache + PubSub │
              │  + Sessões)     │
              └────────┬────────┘
                       │
              ┌────────┴────────┐
              │ Object Storage  │
              │ (Compatível S3) │
              └─────────────────┘
```

> **Nota:** No MVP, todos os esquemas PostgreSQL rodam em uma única instância usando schemas separados por serviço. Em produção, cada serviço pode ser migrado para sua própria instância de banco.

---

## 2. Fronteiras dos Serviços

| Serviço | Responsável Por | Comunica-se Com |
|:---|:---|:---|
| **API Gateway** | Regras de roteamento, limites de taxa | Todos os serviços (proxy HTTP) |
| **Serviço Auth** | Credenciais de usuários, tokens, códigos OTP, instituições | Redis (cache de sessão), Serviço Profile (evento de criação de usuário) |
| **Serviço Profile** | Perfis de usuários, habilidades, conexões | Serviço Auth (valida tokens), Serviço Feed (eventos de perfil), Redis (cache de perfil) |
| **Serviço Feed** | Posts, reações, comentários | Serviço Profile (dados do autor), Redis (cache do feed) |
| **Serviço Messaging** | Chats, mensagens, membros de grupo | Serviço Profile (consulta de usuário), Redis (pub/sub para tempo real), Object Storage (arquivos) |

---

## 3. Padrões de Comunicação

### 3.1 Síncrono (HTTP/REST)
- **Gateway → Serviços**: Todas as requisições do cliente passam pelo proxy HTTP para o serviço apropriado.
- **Consultas inter-serviço**: Quando o Serviço A precisa de dados do Serviço B durante uma requisição, ele faz uma chamada HTTP síncrona (ex: Serviço Feed busca perfil do autor no Serviço Profile).

### 3.2 Assíncrono (Eventos via Redis Pub/Sub + BullMQ)

Eventos são publicados em canais Redis e processados assincronamente pelos serviços consumidores.

```text
Serviço Produtor  ──▶  Canal Redis  ──▶  Serviço(s) Consumidor(es)
```

| Evento | Produtor | Consumidor(es) | Propósito |
|:---|:---|:---|:---|
| `user.registered` | Serviço Auth | Serviço Profile | Criar registro de perfil inicial |
| `user.deleted` | Serviço Auth | Profile, Feed, Messaging | Cascata de anonimização |
| `profile.updated` | Serviço Profile | Serviço Feed | Invalidar dados do autor em cache |
| `connection.accepted` | Serviço Profile | Serviço Messaging | Habilitar canal de mensagens diretas (DM) |
| `connection.removed` | Serviço Profile | Serviço Messaging | Fechar DM se desejado |
| `post.created` | Serviço Feed | Serviço Notificação* | Disparar notificações do feed |
| `post.deleted` | Serviço Feed | — | Invalidar cache do feed |
| `message.sent` | Serviço Messaging | Serviço Notificação* | Disparar push notification |

*O Serviço de Notificação é um trabalhador (worker) leve, não um microsserviço completo.

### 3.3 Tempo Real (WebSocket)
- O **Serviço Messaging** mantém conexões WebSocket para o chat em tempo real.
- Conexões WebSocket são autenticadas via JWT no aperto de mãos (handshake).
- Para escalar instâncias múltiplas, usa-se o adaptador **Redis Pub/Sub** do Socket.IO para dispersão de mensagens (fan-out) entre réplicas.

---

## 4. Responsabilidades do API Gateway

| Responsabilidade | Implementação |
|:---|:---|
| **Roteamento de Requisições** | Encaminhar `/api/v1/auth/*` → Serviço Auth, `/api/v1/users/*` → Serviço Profile, etc. |
| **Autenticação** | Validar JWT em cada requisição (exceto endpoints públicos). Rejeitar tokens expirados/revogados. |
| **Limitação de Taxa** | Limites por IP e por usuário usando janela deslizante (sliding window) no Redis. |
| **Validação da Requisição** | Validação básica de esquema (tipo de conteúdo, cabeçalhos obrigatórios). |
| **CORS** | Permitir apenas origens configuradas. Habilitado para credenciais. |
| **Circuit Breaking** | Se um serviço retornar >50% de erros 5xx em 30s, abre-se o circuito por 60s, retornando 503 HTTP ao cliente. |
| **ID da Requisição** | Injetar cabeçalho `X-Request-ID` (UUID) para rastreamento distribuído (tracing). |
| **Compressão** | Gzip para respostas maiores que 1KB. |

---

## 5. Fluxo de Autenticação

```text
┌──────┐       ┌─────────┐       ┌────────────┐      ┌───────┐
│Client│       │ Gateway │       │Serviço Auth│      │ Redis │
└──┬───┘       └────┬────┘       └─────┬──────┘      └───┬───┘
   │                │                   │                  │
   │ POST /auth/register                │                  │
   │ {email}        │                   │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Validar domínio  │
   │                │                   │ Gerar OTP        │
   │                │                   │ Armazenar OTP───►│
   │                │                   │ Enviar e-mail    │
   │                │  202 Aceito       │                  │
   │◄───────────────┤◄─────────────────┤                  │
   │                │                   │                  │
   │ POST /auth/verify-otp              │                  │
   │ {email, code}  │                   │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Verificar OTP───►│
   │                │                   │ (checar Redis)   │
   │                │  {temp_token}     │                  │
   │◄───────────────┤◄─────────────────┤                  │
   │                │                   │                  │
   │ POST /auth/complete-registration   │                  │
   │ {temp_token, password, profile}    │                  │
   ├───────────────►├──────────────────►│                  │
   │                │                   │ Criar usuário    │
   │                │                   │ Hash da senha    │
   │                │                   │ Emitir par JWT   │
   │                │                   │ Armazenar refresh►
   │                │                   │ Emitir user.registered
   │                │  {access, refresh}│                  │
   │◄───────────────┤◄─────────────────┤                  │
```

---

## 6. Pipeline de Geração do Feed

```text
┌──────────────────────────────────────────────────────────┐
│              Fluxo de Requisição do Feed                 │
│                                                          │
│  1. Cliente solicita GET /posts?scope=global&cursor=xxx  │
│                         │                                │
│  2. Gateway valida JWT e encaminha para Serviço Feed     │
│                         │                                │
│  3. Serviço Feed verifica cache no Redis                 │
│     ┌───────────────────┴──────────────────┐             │
│     │ Cache ACERTO              Cache ERRO │             │
│     │ Retorna feed             Consulta PG │             │
│     │                         │            │             │
│     │          Aplica Exploração Forçada:  │             │
│     │          - 80% da IES do usuário     │             │
│     │          - 20% de outras IES         │             │
│     │                         │            │             │
│     │          Mescla + Ordena por data    │             │
│     │                         │            │             │
│     │          Enriquece com perfis        │             │
│     │          (lote do Serviço Profile)   │             │
│     │                         │            │             │
│     │          Cacheia feed no Redis (60s) │             │
│     │                         │            │             │
│     └─────────────────────────┘            │             │
│                                            │             │
│  4. Retornar resposta paginada ao cliente  │             │
└────────────────────────────────────────────┘
```

### Estratégia de Invalidação de Cache
- **Por tempo**: Tempo de vida (TTL) no Redis de 60 segundos.
- **Por eventos**: Eventos `post.created` e `post.deleted` deletam do cache o feed local da instituição daquele autor.
- **Personalizada (Por Usuário)**: O cache do feed global salva na chave `[user_institution_id]:cursor`, blindando o Feed Exploratório para quem visita de diferentes universidades.

---

## 7. Arquitetura de Mensagens

```text
┌────────┐    WSS     ┌──────────────┐    Redis PubSub    ┌──────────────┐
│Client A├───────────►│  Messaging   │◄──────────────────►│  Messaging   │
│        │◄───────────┤  Instância 1 │                    │  Instância 2 │
└────────┘            └──────┬───────┘                    └──────┬───────┘
                             │                                   │    WSS
                             │ Persistir                  ┌──────┴───────┐
                             ▼                            │   Client B   │
                      ┌──────────────┐                    └──────────────┘
                      │  msg_db      │
                      │ (PostgreSQL) │
                      └──────────────┘
```

### Como funciona:
1. O aplicativo conecta via WebSocket (Socket.IO) enviando o token JWT no handshake de autenticação.
2. O messaging-service autentica a conexão e inscreve o usuário nas salas dos seus chats ativos.
3. Quando o Cliente A envia uma mensagem:
   a. A mensagem é persistida no PostgreSQL.
   b. É publicada no canal `chat:{chat_id}` do Redis via Pub/Sub.
   c. As instâncias do Messaging Service que hospedam os clientes do chat entregam a mensagem ao Cliente B via WebSocket.
4. Se o Cliente B está offline, o evento é encaminhado para os workers de notificação push (Firebase).

---

## 8. Stack de Tecnologias

| Camada | Tecnologia | Justificativa |
|:---|:---|:---|
| **Framework Backend** | NestJS (Node.js + TypeScript) | Injeção de dependência nativa, arquitetura modular, suporte integrado a microsserviços |
| **App Mobile** | Flutter (Dart) | Codebase único gerando apps iOS e Android nativos com alto desempenho |
| **Banco de Dados** | PostgreSQL 16 | Suporte robusto a JSONB, transações ACID e Row-Level Security |
| **Cache e Pub/Sub** | Redis 7 | Cache de feed (60s TTL), sessões OTP e canal Pub/Sub para WebSockets |
| **Filas Assíncronas** | BullMQ (sobre Redis) | Jobs em background (e-mail, notificações, invalidação de cache) sem bloquear a requisição |
| **Object Storage** | MinIO (dev) / S3 (produção) | Armazenamento de avatares e arquivos de posts com URLs pré-assinadas |
| **WebSocket** | Socket.IO | Gerencia reconexões automáticas e fan-out entre instâncias via Redis adapter |
| **Notificações Push** | Firebase Cloud Messaging (FCM) | Entrega de notificações para iOS e Android quando o app está em background |
| **Infraestrutura Local** | Docker + Docker Compose | Ambiente de desenvolvimento reproduzível e isolado |
