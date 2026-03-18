# Padrões e Contexto Persistente — InteraEdu

> **LEIA ESTE ARQUIVO ANTES DE QUALQUER IMPLEMENTAÇÃO.**
> Ele funciona como memória do projeto para qualquer desenvolvedor ou IA que continuar o trabalho.

---

## 1. Decisões Arquiteturais Tomadas

| Decisão | Motivo |
|---|---|
| **Microsserviços NestJS** | Escalabilidade e isolamento de falhas por domínio de negócio |
| **Schema PostgreSQL por serviço** | Evitar acoplamento entre serviços via banco; cada serviço é dono dos seus dados |
| **Redis para OTP** | TTL nativo de 10 minutos, sem poluição no banco relacional |
| **Refresh token como hash bcrypt** | Nunca armazenar token em texto plano; proteção contra vazamento de banco |
| **Rotação de refresh token** | A cada uso, o refresh token antigo é revogado e um novo emitido |
| **Paginação por cursor** | Scroll infinito sem problemas de offset em grandes volumes |
| **Feed local prioritário** | Conteúdo da mesma instituição aparece antes; complementado com global se < 5 posts |
| **Privacidade de perfil em 3 níveis** | `public`, `local_only`, `private` — conforme requisitos do produto |
| **Flutter Clean Architecture** | Separação clara: domínio não depende de infraestrutura; facilita testes e manutenção |
| **Pacote `http` no mobile** | Escolha minimalista para o MVP; migrar para `dio` se necessário interceptors avançados |

---

## 2. Premissas Importantes

1. **Todo usuário deve ter e-mail institucional** — domínio validado contra a tabela `institutions` no banco `auth`.
2. **O API Gateway é o único ponto de entrada externo** — serviços individuais não devem ser expostos em produção.
3. **Dados de e-mail ficam apenas no auth-service** — o profile-service não armazena e-mail (princípio de menor exposição).
4. **Soft delete universal** — nunca deletar registros fisicamente; usar o campo `deleted_at`.
5. **Eventos são best-effort no MVP** — Redis Pub/Sub sem garantia de entrega; usar message broker (RabbitMQ/Kafka) no futuro para garantia de entrega.
6. **MinIO em desenvolvimento, S3 em produção** — compatibilidade total via AWS SDK.
7. **Um único banco PostgreSQL em desenvolvimento** com schemas separados; em produção pode migrar para bancos separados por serviço.

---

## 3. Regras de Negócio Principais

### Autenticação
- Domínio do e-mail deve estar cadastrado na tabela `institutions`.
- OTP expira em 10 minutos (armazenado no Redis).
- Após verificação do OTP, o `temporary_token` (JWT) expira em 15 minutos.
- Access token: 15 minutos.
- Refresh token: 7 dias, com rotação a cada uso.
- Detecção de replay attack: se um refresh token revogado for utilizado, todos os tokens do usuário são revogados.

### Registro
1. `POST /auth/register` → valida domínio → envia OTP por e-mail.
2. `POST /auth/verify-otp` → valida OTP → retorna `temporary_token`.
3. `POST /auth/complete-registration` → usa `temporary_token` → cria conta → registra consentimento (ToS + Política de Privacidade) → emite access token e refresh token.

### Feed
- Scope `local`: posts da mesma instituição (com visibilidade `public` ou `local_only`).
- Scope `global`: 80% local + 20% de outras instituições.
- Cache no Redis de 60 segundos por combinação de (scope + institution_id + cursor + limit).
- Posts com soft delete (`deleted_at` preenchido) não aparecem no feed.

### Perfil e Privacidade
- `public`: visível para todos os usuários autenticados.
- `local_only`: visível apenas para a mesma instituição OU para usuários conectados.
- `private`: visível apenas para conexões aceitas.
- A busca de usuários respeita as mesmas regras de privacidade.

### Conexões
- Uma solicitação por par de usuários (verificar antes de criar).
- Estados: `pending` → `accepted` ou `rejected`.
- Conexão é bidirecional: se A conecta com B, B também é conexão de A.

---

## 4. Estrutura de Pastas Padrão

### Backend — Novo Serviço

```
novo-service/
├── Dockerfile
├── package.json
├── tsconfig.json
└── src/
    ├── main.ts                 # Bootstrap NestJS
    ├── app.module.ts           # AppModule raiz
    ├── database/
    │   ├── database.module.ts  # Configuração TypeORM
    │   └── entities/           # Entidades TypeORM
    │       └── *.entity.ts
    └── feature/                # Um módulo por funcionalidade
        ├── feature.module.ts
        ├── feature.controller.ts
        ├── feature.service.ts
        └── dto/
            └── *.dto.ts
```

### Mobile Flutter — Nova Funcionalidade

```
lib/presentation/novo_feature/
├── screens/
│   └── novo_feature_screen.dart
└── widgets/
    └── novo_feature_widget.dart

lib/domain/
├── entities/novo_feature_entity.dart
└── repositories/novo_feature_repository.dart  # interface abstrata

lib/data/
├── models/novo_feature_model.dart
└── repositories/novo_feature_repository_impl.dart
```

---

## 5. Convenções de Nomenclatura

### Backend
| Elemento | Padrão | Exemplo |
|---|---|---|
| Arquivos | `kebab-case` | `auth.service.ts` |
| Classes | `PascalCase` | `AuthService` |
| Variáveis/métodos | `camelCase` | `findByEmail()` |
| Constantes | `UPPER_SNAKE_CASE` | `BCRYPT_ROUNDS` |
| Tabelas no banco | `snake_case` plural | `user_credentials` |
| Colunas no banco | `snake_case` | `created_at`, `institution_id` |
| Eventos Redis | `domínio.verbo` | `user.registered`, `post.created` |
| Códigos de erro | `UPPER_SNAKE_CASE` | `INVALID_CREDENTIALS` |

### Mobile Flutter
| Elemento | Padrão | Exemplo |
|---|---|---|
| Arquivos | `snake_case` | `login_screen.dart` |
| Classes | `PascalCase` | `LoginScreen` |
| Variáveis/métodos | `camelCase` | `onLoginPressed()` |
| Constantes | `lowerCamelCase` | `apiBaseUrl` |

---

## 6. Padrões de API

### Requisição
```
Authorization: Bearer {access_token}
Content-Type: application/json
X-Request-ID: {uuid}  (recomendado para rastreabilidade)
```

### Resposta de Sucesso — Lista Paginada
```json
{
  "data": [...],
  "pagination": {
    "cursor": "base64string ou null",
    "has_more": true
  }
}
```

### Resposta de Erro
```json
{
  "statusCode": 400,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Mensagem legível por humanos",
    "details": [...]
  }
}
```

### Cursor de Paginação
```typescript
// Encode
Buffer.from(JSON.stringify({ t: date.toISOString() })).toString('base64')

// Decode
JSON.parse(Buffer.from(cursor, 'base64').toString('utf8')).t
```

---

## 7. Fluxo Padrão de Dados

### Backend — Dentro de um Microsserviço
```
Requisição HTTP
    ↓
Controller (valida DTO via ValidationPipe, extrai @CurrentUser)
    ↓
Service (regras de negócio)
    ↓
Repository (TypeORM) → PostgreSQL
    ↓ (opcional)
RedisService → cache/pub-sub
```

### Mobile — Fluxo de Funcionalidade
```
Screen (UI + estado local)
    ↓
Repository Interface (domain)
    ↓
Repository Impl (data)
    ↓
ApiClient.get/post/patch/delete
    ↓ (via SecureStorage para token)
API Gateway
```

---

## 8. Riscos Técnicos Identificados

| Risco | Impacto | Mitigação |
|---|---|---|
| Refresh token não implementado no mobile | Alto — usuário perde sessão após 15min | Implementar M-02 imediatamente |
| Redis Pub/Sub sem garantia de entrega | Médio — perfil pode não ser criado automaticamente | Implementar B-01 com idempotência e retry |
| N+1 queries no profile-service (skills, links) | Médio — lento com muitos usuários | Adicionar eager loading ou DataLoader |
| Cache do feed com TTL curto sem invalidação por chave | Baixo — dados ligeiramente desatualizados | Aceitável para o MVP; melhorar com scan de chaves no futuro |
| Sem testes automatizados | Alto — regressões difíceis de detectar | Priorizar após a fase M-04 |
| `pubspec.yaml` sem gerenciamento de estado | Médio — ausência de state management global | Adicionar `provider` ou `riverpod` em M-01 |

---

## 9. Instruções para Continuar o Projeto

### SEMPRE:
- Criar novos arquivos seguindo a estrutura de pastas padrão descrita na seção 4.
- Atualizar `api_endpoints.dart` ao adicionar novos endpoints no backend.
- Marcar como concluído (✅) as tarefas em `docs/guias/tarefas-ia.md` ao completá-las.
- Atualizar o status em `docs/mvp/status-implementacao.md` ao alterar o estado de funcionalidades.
- Usar `@interaedu/shared` para JWT, Redis e Guards no backend — nunca duplicar.
- Seguir o contrato de erro `{ error: { code, message } }` em todos os endpoints.

### NUNCA:
- Criar JOINs entre schemas de serviços diferentes no banco.
- Armazenar tokens JWT em texto plano (sempre hash bcrypt para refresh tokens).
- Adicionar lógica de negócio em Controllers ou em Widgets do Flutter.
- Usar `console.log` no backend — usar o `Logger` do NestJS.
- Modificar entidades compartilhadas sem verificar seu uso em todos os serviços.
- Criar endpoints sem DTO de validação no backend.
- Chamar `ApiClient` diretamente a partir de uma Screen no Flutter.

---

## 10. Contexto do Produto

**InteraEdu** é uma rede social exclusiva para a comunidade acadêmica universitária brasileira.

- **Público-alvo:** Estudantes de graduação e pós-graduação de instituições parceiras.
- **Diferencial:** Identidade verificada por domínio de e-mail institucional (sem contas falsas).
- **Modelo:** Gratuito para usuários; monetização futura via instituições/empresas (B2B).
- **Conformidade:** Deve seguir a LGPD — campo de consentimento no registro, endpoint de exclusão de conta (`DELETE /users/me`), exportação de dados (`GET /users/me/export`).
- **Design:** Paleta verde (trevo)/neutros; Material Design 3; identidade amigável e acadêmica.

---

## 11. Variáveis de Ambiente — Referência Completa

```env
# Segredos JWT
JWT_ACCESS_SECRET=<string aleatória 64+ chars>
JWT_REFRESH_SECRET=<string aleatória 64+ chars, diferente da anterior>
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# Banco de dados
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=interaedu
DATABASE_USERNAME=interaedu
DATABASE_PASSWORD=<senha forte em produção>
DATABASE_SCHEMA=<auth|profile|feed|messaging>

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# SMTP
SMTP_HOST=<host de e-mail>
SMTP_PORT=587
SMTP_USER=<usuário>
SMTP_PASS=<senha>
SMTP_FROM=noreply@interaedu.com.br

# MinIO / S3
S3_ENDPOINT=http://minio:9000
S3_BUCKET=interaedu
S3_ACCESS_KEY=<access key>
S3_SECRET_KEY=<secret key>

# Google OAuth (futuro)
GOOGLE_CLIENT_ID=<id do console.cloud.google.com>
GOOGLE_CLIENT_SECRET=<secret>
GOOGLE_CALLBACK_URL=http://localhost:3000/api/v1/auth/google/callback

# CORS
CORS_ORIGINS=http://localhost:3000,https://interaedu.com.br
```
