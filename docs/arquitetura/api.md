# InteraEdu — Design de API

**Versão:** 2.0
**Data:** Março 2026
**URL Base:** `https://api.interaedu.com/api/v1`

---

## 1. Princípios de Design

| Princípio | Implementação |
|:---|:---|
| **RESTful** | Recursos nomeados como substantivos; verbos HTTP definem a ação |
| **Versionada** | Prefixo explícito de versão na URL (`/api/v1/`) |
| **Paginada por cursor** | Todas as listas utilizam paginação por cursor para suportar scroll infinito |
| **Envelope de erro padronizado** | Todo erro retorna o mesmo formato JSON |
| **Autenticação via Bearer** | `Authorization: Bearer <JWT>` obrigatório em todos os endpoints protegidos |
| **JSON como padrão** | `Content-Type: application/json` em todas as trocas de dados |
| **Idempotência** | PUT/DELETE são idempotentes por natureza; POSTs críticos aceitam o header `X-Idempotency-Key` |

---

## 2. Endpoints de Autenticação

### `POST /api/v1/auth/register`
Inicia o fluxo de registro. Valida o domínio do e-mail contra as instituições cadastradas e envia um OTP por e-mail.

**Requisição:**
```json
{
  "email": "ana@aluno.ufmg.br"
}
```

**Resposta:** `202 Accepted`
```json
{
  "message": "OTP enviado para o e-mail institucional.",
  "expires_in_seconds": 600
}
```

**Erros:** `422` (formato de e-mail inválido), `403` (domínio não cadastrado como institucional), `429` (muitas requisições do mesmo IP)

---

### `POST /api/v1/auth/verify-otp`
Valida o código OTP de 6 dígitos. Em caso de sucesso, retorna um `temporary_token` com validade de 15 minutos para completar o registro.

**Requisição:**
```json
{
  "email": "ana@aluno.ufmg.br",
  "code": "482951"
}
```

**Resposta:** `200 OK`
```json
{
  "temporary_token": "eyJ...",
  "expires_in_seconds": 900
}
```

**Erros:** `401` (código incorreto), `410` (OTP expirado após 10 minutos), `429` (muitas tentativas — bloqueio de 15 minutos)

---

### `POST /api/v1/auth/complete-registration`
Finaliza o cadastro com dados de perfil e registro de consentimento (Termos de Uso e Política de Privacidade, conforme LGPD).

**Headers:** `Authorization: Bearer <temporary_token>`

**Requisição:**
```json
{
  "password": "Senha@Forte33!",
  "full_name": "Ana Silva",
  "course": "Ciências da Computação",
  "period": 3,
  "skill_ids": ["uuid-python", "uuid-react"],
  "consent": {
    "terms_version": "v1.0",
    "privacy_version": "v1.0"
  }
}
```

**Resposta:** `201 Created`
```json
{
  "user": {
    "id": "uuid-user",
    "email": "ana@aluno.ufmg.br",
    "full_name": "Ana Silva",
    "institution": {
      "id": "uuid-ufmg",
      "name": "UFMG"
    }
  },
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

---

### `POST /api/v1/auth/login`
Autentica um usuário já registrado com e-mail e senha.

**Requisição:**
```json
{
  "email": "ana@aluno.ufmg.br",
  "password": "Senha@Forte33!"
}
```

**Resposta:** `200 OK`
```json
{
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Erros:** `401` (credenciais inválidas), `403` (conta suspensa ou bloqueada)

---

### `POST /api/v1/auth/refresh`
Emite um novo par de tokens (access + refresh) a partir de um refresh token válido. O refresh token enviado é revogado após o uso (rotação).

**Requisição:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Resposta:** `200 OK`
```json
{
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Erros:** `401` (refresh token inválido, expirado ou já revogado)

---

### `POST /api/v1/auth/logout`
Revoga o refresh token especificado no servidor, invalidando a sessão atual.

**Headers:** `Authorization: Bearer <access_token>`

**Requisição:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Resposta:** `204 No Content`

---

## 3. Endpoints de Perfil

### `GET /api/v1/users/me`
Retorna os dados completos do perfil do usuário autenticado, incluindo campos privados (e-mail, nível de privacidade).

**Resposta:** `200 OK`
```json
{
  "id": "uuid-user",
  "email": "ana@aluno.ufmg.br",
  "full_name": "Ana Silva",
  "bio": "Estudante apaixonada por Machine Learning.",
  "course": "Ciência da Computação",
  "period": 3,
  "privacy_level": "local_only",
  "avatar_url": "https://cdn.interaedu.com/avatars/uuid.jpg",
  "institution": {
    "id": "uuid-ufmg",
    "name": "UFMG",
    "slug": "ufmg"
  },
  "skills": [
    { "id": "uuid-python", "name": "Python", "category": "programming" }
  ],
  "links": [
    { "id": "uuid-link", "type": "github", "url": "https://github.com/anasilva" }
  ],
  "created_at": "2026-03-01T12:00:00Z"
}
```

---

### `PATCH /api/v1/users/me`
Atualiza parcialmente o perfil do usuário autenticado.

**Requisição:**
```json
{
  "bio": "Nova biografia",
  "period": 4,
  "skill_ids": ["uuid-python", "uuid-ml", "uuid-react"],
  "privacy_level": "public"
}
```

**Resposta:** `200 OK` (retorna o perfil atualizado completo)

---

### `DELETE /api/v1/users/me`
Solicita a exclusão da conta. Implementa o Direito ao Esquecimento conforme LGPD. A exclusão é agendada para 30 dias após a solicitação.

**Requisição:**
```json
{
  "password": "Senha@Forte33!",
  "confirmation": "EXCLUIR MINHA CONTA"
}
```

**Resposta:** `202 Accepted`
```json
{
  "message": "Solicitação de exclusão recebida. Os dados serão anonimizados em 30 dias.",
  "deletion_scheduled_at": "2026-04-15T00:00:00Z"
}
```

---

### `GET /api/v1/users/me/data-export`
Solicita a exportação de todos os dados do usuário em formato JSON compactado (portabilidade de dados, LGPD). O arquivo é enviado por e-mail em até 48 horas.

**Resposta:** `202 Accepted`
```json
{
  "message": "Exportação de dados iniciada. Você receberá o arquivo por e-mail em até 48 horas.",
  "request_id": "uuid-export-request"
}
```

---

### `GET /api/v1/users/:id`
Retorna o perfil público de um usuário. Respeita as configurações de privacidade do alvo e a relação entre os usuários (mesma instituição, conectados, bloqueados).

**Resposta:** `200 OK` (mesmo formato do `/me`, omitindo campos privados como e-mail)

**Erros:** `404` (usuário não encontrado, excluído, bloqueado pelo alvo, ou inacessível por restrição de privacidade)

---

### `GET /api/v1/users/search`
Busca usuários por nome completo, habilidades, curso ou instituição.

**Parâmetros de query:**

| Parâmetro | Tipo | Descrição |
|:---|:---|:---|
| `q` | string | Busca em texto completo pelo nome do usuário |
| `skill` | string | Slug da habilidade (ex: `python`) |
| `institution` | string | Slug da instituição (ex: `usp`) |
| `course` | string | Filtro pelo nome do curso |
| `cursor` | string | Cursor de paginação |
| `limit` | integer | Itens por página (padrão: 20, máximo: 50) |

**Resposta:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid-user",
      "full_name": "Carlos Lima",
      "course": "Biotecnologia",
      "institution": { "id": "uuid-usp", "name": "USP" },
      "skills": [
        { "id": "uuid-ml", "name": "Machine Learning" }
      ],
      "avatar_url": "https://cdn.interaedu.com/avatars/uuid.jpg"
    }
  ],
  "pagination": {
    "cursor": "cursor-base64",
    "has_more": true,
    "total_count": 142
  }
}
```

---

## 4. Endpoints de Conexões

### `POST /api/v1/connections`
Envia uma solicitação de conexão para outro usuário.

**Requisição:**
```json
{
  "addressee_id": "uuid-target-user",
  "message": "Olá, vi seu perfil e gostaria de conversar sobre Machine Learning."
}
```

**Resposta:** `201 Created`

**Erros:** `409` (solicitação duplicada ou já existente), `403` (usuário bloqueado), `404` (usuário não encontrado)

---

### `GET /api/v1/connections`
Lista as conexões do usuário autenticado.

**Parâmetros opcionais:**

| Parâmetro | Tipo | Descrição |
|:---|:---|:---|
| `status` | string | Filtrar por: `pending`, `accepted` |
| `direction` | string | Filtrar por: `sent` (enviadas), `received` (recebidas) |
| `cursor` | string | Cursor de paginação |

---

### `PATCH /api/v1/connections/:id`
Aceita ou rejeita uma solicitação de conexão recebida.

**Requisição:**
```json
{
  "action": "accept"
}
```

**Resposta:** `200 OK`

---

### `DELETE /api/v1/connections/:id`
Remove uma conexão existente.

**Resposta:** `204 No Content`

---

## 5. Endpoints de Feed

### `GET /api/v1/posts`
Retorna o feed de posts paginado por cursor.

**Parâmetros de query:**

| Parâmetro | Tipo | Descrição |
|:---|:---|:---|
| `scope` | string | `local` (apenas minha instituição) ou `global` (mista, com 80% local + 20% outras) |
| `cursor` | string | Cursor de paginação para scroll infinito |
| `limit` | integer | Itens por página (padrão: 20) |

**Resposta:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid-post",
      "author": {
        "id": "uuid-user",
        "full_name": "Ana Silva",
        "institution": { "name": "UFMG" },
        "avatar_url": "..."
      },
      "content": "Encontrei um gargalo interessante em processamento de linguagem natural. Alguém trabalhando com NLP que possa trocar ideias?",
      "scope": "global",
      "media_urls": [],
      "reaction_count": 5,
      "comment_count": 2,
      "user_reaction": "like",
      "created_at": "2026-03-15T10:30:00Z"
    }
  ],
  "pagination": {
    "cursor": "cursor-base64",
    "has_more": true
  }
}
```

---

### `POST /api/v1/posts`
Cria um novo post. Invalida automaticamente o cache do feed da instituição do autor no Redis.

**Requisição:**
```json
{
  "content": "Estou estudando cálculo diferencial e gostaria de trocar dicas com outros estudantes.",
  "scope": "global",
  "media_urls": ["https://s3.../file.pdf"]
}
```

**Resposta:** `201 Created`

---

### `DELETE /api/v1/posts/:id`
Remove um post com soft delete (campo `deleted_at` preenchido; dados não são apagados fisicamente).

**Resposta:** `204 No Content`

**Erros:** `403` (tentativa de deletar post de outro usuário), `404` (post não encontrado)

---

### `POST /api/v1/posts/:id/reactions`
Registra uma reação em um post. O sistema não possui reações negativas — apenas reações de apoio e reconhecimento.

**Requisição:**
```json
{
  "type": "insightful"
}
```

**Resposta:** `201 Created`

**Erros:** `409` (usuário já reagiu a este post)

---

### `GET /api/v1/posts/:id/comments`
Retorna os comentários de um post, paginados por cursor, em ordem cronológica crescente.

---

### `POST /api/v1/posts/:id/comments`
Adiciona um comentário a um post. Suporta respostas aninhadas via `parent_comment_id`.

**Requisição:**
```json
{
  "content": "Interessante! Me conecta, gostaria de continuar esse papo.",
  "parent_comment_id": null
}
```

**Resposta:** `201 Created`

---

## 6. Endpoints de Mensagens (Chats)

### `GET /api/v1/chats`
Lista todos os chats do usuário autenticado com o preview da última mensagem.

**Parâmetros de query:**

| Parâmetro | Tipo | Descrição |
|:---|:---|:---|
| `type` | string | Filtrar por: `direct`, `group` |
| `cursor` | string | Cursor de paginação |

**Resposta:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid-chat",
      "type": "direct",
      "name": null,
      "participants": [
        { "id": "uuid-user-b", "full_name": "Carlos Lima", "avatar_url": "..." }
      ],
      "last_message": {
        "content": "Combinado! Nos falamos amanhã.",
        "sent_at": "2026-03-15T14:30:00Z",
        "sender_id": "uuid-user-b"
      },
      "unread_count": 2
    }
  ],
  "pagination": { "cursor": "...", "has_more": false }
}
```

---

### `POST /api/v1/chats`
Cria um novo chat individual (direct) ou em grupo.

**Chat direto (1:1):**
```json
{
  "type": "direct",
  "participant_ids": ["uuid-user-b"]
}
```

**Chat em grupo:**
```json
{
  "type": "group",
  "name": "Grupo ML Avançado",
  "description": "Discussões sobre Machine Learning aplicado.",
  "topic_tags": ["machine-learning", "python"],
  "participant_ids": ["uuid-a", "uuid-b", "uuid-c"]
}
```

**Resposta:** `201 Created`

**Erros:** `409` (chat direto com este usuário já existe), `403` (tentativa de chat com usuário sem conexão estabelecida)

---

### `GET /api/v1/chats/:id/messages`
Retorna o histórico de mensagens de um chat, paginado por cursor (mais recentes primeiro).

---

### `POST /api/v1/chats/:id/messages`
Envia uma mensagem via HTTP (fallback para quando o WebSocket não está disponível).

**Requisição:**
```json
{
  "content": "Bora marcar uma chamada amanhã para fechar os detalhes?",
  "file_url": null
}
```

**Resposta:** `201 Created`

---

### `POST /api/v1/upload/presign`
Gera uma URL pré-assinada para upload direto de arquivo do cliente para o S3/MinIO, sem passar pelo servidor NestJS. Recomendado para arquivos grandes.

**Requisição:**
```json
{
  "file_name": "tese_final.pdf",
  "content_type": "application/pdf",
  "size_bytes": 2048576
}
```

**Resposta:** `200 OK`
```json
{
  "upload_url": "https://s3.amazonaws.com/...",
  "file_url": "https://cdn.interaedu.com/files/uuid-file.pdf",
  "expires_in_seconds": 3600
}
```

**Erros:** `413` (arquivo excede o limite de 10MB), `415` (tipo de arquivo não permitido)

---

## 7. Endpoints de Habilidades

### `GET /api/v1/skills`
Retorna todas as habilidades cadastradas, agrupadas por categoria.

### `GET /api/v1/skills/search?q=pyth`
Autocomplete de habilidades pelo nome (ex: digitar `pyt` retorna `Python`, `PyTorch`).

---

## 8. Endpoints de Notificações

### `GET /api/v1/notifications`
Retorna o histórico de notificações do usuário.

### `PATCH /api/v1/notifications/:id/read`
Marca uma notificação específica como lida.

### `PATCH /api/v1/notifications/read-all`
Marca todas as notificações do usuário como lidas.

---

## 9. Endpoints de Administração

### `POST /api/v1/admin/institutions`
Cadastra uma nova instituição de ensino com seus domínios de e-mail validados.

### `PATCH /api/v1/admin/institutions/:id`
Atualiza dados de uma instituição (nome, domínios, status ativo/inativo).

### `GET /api/v1/admin/reports`
Lista as denúncias de conteúdo com status `pending` para revisão manual.

### `PATCH /api/v1/admin/reports/:id`
Processa uma denúncia: aprovar (remover conteúdo) ou rejeitar (manter conteúdo).

---

## 10. Formato Padrão de Erro

Todos os erros seguem o mesmo envelope JSON, facilitando o tratamento no cliente:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "O domínio do e-mail informado não está cadastrado como domínio institucional.",
    "status": 403,
    "details": [
      {
        "field": "email",
        "message": "Apenas e-mails com domínio institucional são aceitos."
      }
    ],
    "request_id": "uuid-request-id",
    "timestamp": "2026-03-15T10:30:00Z"
  }
}
```

### Códigos de Erro

| Status HTTP | Código | Descrição |
|:---|:---|:---|
| 400 | `BAD_REQUEST` | Corpo da requisição malformado |
| 401 | `UNAUTHORIZED` | Token JWT ausente, inválido ou expirado |
| 403 | `FORBIDDEN` | Token válido, mas sem permissão para o recurso (conta suspensa, domínio inválido, etc.) |
| 404 | `NOT_FOUND` | Recurso não encontrado, excluído ou inacessível por restrição de privacidade |
| 409 | `CONFLICT` | Conflito de estado — ex: solicitação de conexão duplicada |
| 410 | `GONE` | Recurso expirado — ex: OTP vencido |
| 413 | `PAYLOAD_TOO_LARGE` | Arquivo ou corpo da requisição excede o limite permitido |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | Tipo de arquivo não suportado |
| 422 | `VALIDATION_ERROR` | Dados da requisição falham na validação dos DTOs |
| 429 | `RATE_LIMITED` | Limite de requisições atingido; aguarde o período de cooldown |
| 500 | `INTERNAL_ERROR` | Erro interno não esperado no servidor |
| 503 | `SERVICE_UNAVAILABLE` | Serviço dependente indisponível (circuit breaker ativo) |

---

## 11. Headers

### Headers de Requisição

| Header | Obrigatório | Descrição |
|:---|:---|:---|
| `Authorization` | Sim (exceto endpoints públicos) | `Bearer <JWT>` |
| `Content-Type` | Sim | `application/json` |
| `Accept-Language` | Não | `pt-BR` para mensagens de erro em português |
| `X-Idempotency-Key` | Recomendado em POSTs críticos | UUID único para evitar operações duplicadas em caso de retentativa |

### Headers de Resposta

| Header | Descrição |
|:---|:---|
| `X-Request-ID` | ID único da requisição para rastreamento distribuído (do gateway até os microsserviços) |
| `X-RateLimit-Limit` | Limite total de requisições na janela atual |
| `X-RateLimit-Remaining` | Requisições restantes antes do bloqueio |
| `X-RateLimit-Reset` | Timestamp Unix em que o contador de rate limit é zerado |
