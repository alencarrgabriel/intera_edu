# InteraEdu — Arquitetura de Segurança

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Fluxo de Autenticação

### 1.1 Estratégia JWT

| Token | Duração | Armazenamento | Propósito |
|:---|:---|:---|:---|
| **Access Token** | 15 minutos | Em memória (estado do aplicativo móvel) | Autenticação nas chamadas à API |
| **Refresh Token** | 7 dias | Armazenamento seguro (`flutter_secure_storage`) | Obter novos access tokens |
| **Token Temporário** | 15 minutos | Em memória | Conclusão do registro após verificação do OTP |

### 1.2 Payload do Access Token (Claims JWT)

```json
{
  "sub": "uuid-user-id",
  "iss": "interaedu-auth",
  "iat": 1711234567,
  "exp": 1711235467,
  "institution_id": "uuid-institution",
  "email": "ana@aluno.ufmg.br",
  "roles": ["user"]
}
```

### 1.3 Rotação de Refresh Token
- A cada chamada a `/auth/refresh`, o refresh token antigo é **revogado** e um novo é emitido.
- Se um refresh token já revogado for utilizado novamente (replay attack), **todos** os refresh tokens daquele usuário são revogados (invalidação em família).
- Refresh tokens são armazenados como **hashes bcrypt** na tabela `auth.refresh_tokens`.

### 1.4 Revogação de Token
- **Logout**: O refresh token específico da sessão é revogado.
- **Troca de senha**: Todos os refresh tokens do usuário são revogados.
- **Exclusão de conta**: Todos os tokens são revogados.
- **Sobre blacklist de access tokens**: Como os access tokens têm duração curta (15 min), não há necessidade de blacklist para eles. A revogação do refresh token é verificada diretamente no banco de dados.

---

## 2. Proteção via OTP

### 2.1 Geração de OTP
- Código numérico de 6 dígitos.
- Gerado usando `crypto.randomInt(100000, 999999)` (criptograficamente seguro).
- Armazenado como **hash bcrypt** em `auth.otp_codes` e no Redis com TTL de 10 minutos.

### 2.2 Rate Limiting de OTP

| Limite | Valor | Janela |
|:---|:---|:---|
| Tentativas de verificação de OTP | 5 tentativas | Por e-mail, a cada 15 minutos |
| Reenvio de OTP (novo código) | 3 solicitações | Por e-mail, a cada 1 hora |
| Tentativas de login com falha | 10 tentativas | Por IP, a cada 15 minutos |
| Após bloqueio (lockout) | Bloqueado | Período de cooldown de 15 minutos |

### 2.3 Mitigação de Força Bruta
- Após 5 tentativas falhas de OTP → bloqueio de 15 minutos (rastreado no Redis).
- Após 3 bloqueios consecutivos → conta sinalizada para revisão manual.
- Códigos OTP são de uso único (marcados como `used_at` logo após a verificação).
- Exponential backoff: o tempo de resposta da API aumenta a cada tentativa falha (100ms, 200ms, 400ms...) para dificultar ataques automatizados.

---

## 3. Rate Limiting da API

### 3.1 Estratégia
O rate limiting utiliza um algoritmo de **sliding window no Redis**, aplicado no nível do API Gateway.

### 3.2 Limites

| Categoria do Endpoint | Limite | Janela | Chave |
|:---|:---|:---|:---|
| Endpoints públicos (registro, login) | 20 requisições | 1 minuto | Por IP |
| Endpoints autenticados de leitura | 100 requisições | 1 minuto | Por usuário |
| Endpoints autenticados de escrita | 30 requisições | 1 minuto | Por usuário |
| Upload de arquivos | 10 requisições | 1 hora | Por usuário |
| Pesquisa | 30 requisições | 1 minuto | Por usuário |
| Conexões WebSocket | 5 simultâneas | — | Por usuário |

### 3.3 Headers de Resposta
```text
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1711234627
```

### 3.4 Resposta ao Exceder o Limite
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Limite de requisições excedido. Tente novamente em 43 segundos.",
    "status": 429,
    "retry_after": 43
  }
}
```

---

## 4. Proteção contra Abuso

### 4.1 Validação de Entrada
- Todo corpo de requisição é validado pelos DTOs do NestJS via `class-validator`.
- Injeção de HTML/scripts prevenida por sanitização de saída (DOMPurify para qualquer conteúdo renderizado).
- Injeção de SQL prevenida via queries parametrizadas do TypeORM (nunca concatenação direta de strings).
- Upload de arquivos validado pelo tipo real do arquivo via **magic bytes** (não apenas pela extensão), com limite de tamanho aplicado.

### 4.2 Abuso de Conteúdo
- **Denúncias**: Usuários podem denunciar publicações, comentários, mensagens e perfis.
- **Fila de moderação**: Denúncias entram no painel de administração para revisão manual.
- **Rate limiting para criação de conteúdo**: Máximo de 10 publicações/hora e 50 comentários/hora por usuário.

### 4.3 Abuso de Conta
- Detecção de domínios de e-mail temporários (bloqueio de provedores conhecidos de e-mail descartável).
- Uma conta por e-mail institucional (garantido por constraint `UNIQUE`).
- Capacidade de suspensão de conta pelos administradores.

---

## 5. Lógica de Privacidade de Perfil

### 5.1 Matriz de Visibilidade

| Relação do Visitante | Alvo: `público` | Alvo: `apenas_local` | Alvo: `privado` |
|:---|:---|:---|:---|
| Mesma instituição | ✅ Perfil completo | ✅ Perfil completo | ❌ Oculto |
| Instituição diferente, sem conexão | ✅ Perfil completo | ❌ Oculto | ❌ Oculto |
| Instituição diferente, com conexão | ✅ Perfil completo | ✅ Perfil completo | ✅ Perfil completo |
| Bloqueado pelo alvo | ❌ Oculto | ❌ Oculto | ❌ Oculto |

### 5.2 Implementação
A privacidade é aplicada em dois níveis:
1. **Nível de banco de dados**: Políticas de Row-Level Security (RLS) do PostgreSQL filtram queries com base no `institution_id` e no status de conexão do usuário solicitante.
2. **Nível de aplicação**: O Profile Service aplica verificações de privacidade antes de retornar os dados.

### 5.3 Visibilidade na Pesquisa
Os resultados da pesquisa **excluem** perfis que o usuário solicitante não tem permissão de visualizar. A query de busca inclui um JOIN para verificar o nível de privacidade e o status de conexão.

---

## 6. Criptografia de Dados

### 6.1 Dados em Trânsito
- **TLS 1.3** aplicado em todas as conexões (API, WebSocket, banco de dados, Redis).
- Headers HSTS com `max-age` de 1 ano.
- Certificate pinning no aplicativo Flutter em produção.

### 6.2 Dados em Repouso
- **PostgreSQL**: Criptografia em repouso via criptografia em nível de disco (AWS EBS / GCP Persistent Disk).
- **Arquivos S3**: Criptografia server-side (SSE-S3 ou SSE-KMS).
- **Senhas**: bcrypt com fator de custo 12.
- **Códigos OTP**: armazenados com hash bcrypt.
- **Refresh tokens**: armazenados com hash SHA-256 no banco; apenas o hash é persistido.

### 6.3 Campos Sensíveis
| Campo | Proteção |
|:---|:---|
| `password_hash` | bcrypt (fator de custo 12) |
| Códigos OTP | bcrypt no banco + TTL no Redis |
| Refresh tokens | SHA-256 armazenado |
| Endereços de e-mail | Texto simples (necessário para autenticação); acesso controlado por RLS |
| Endereços IP (auditoria) | Armazenados por 5 anos conforme requisitos de auditoria da LGPD |

> **Observação:** Criptografia de ponta-a-ponta (E2E) para mensagens **não está implementada** no MVP. As mensagens são criptografadas em trânsito (TLS) e em repouso (criptografia de disco), mas são legíveis pelo servidor para fins de moderação. A implementação de E2E inviabilizaria a moderação de conteúdo e a busca de mensagens.

---

## 7. Política de Senhas

| Requisito | Valor |
|:---|:---|
| Comprimento mínimo | 8 caracteres |
| Comprimento máximo | 128 caracteres |
| Classes de caracteres obrigatórias | 1 maiúscula, 1 minúscula, 1 número, 1 caractere especial |
| Verificação de senhas vazadas | Consulta à API HaveIBeenPwned (modelo k-anônimato) |
| Histórico de senhas | Não é permitido reutilizar as últimas 3 senhas |
| Algoritmo de hash | bcrypt, fator de custo 12 |

---

## 8. Política de CORS

```typescript
// Configuração de CORS do API Gateway
{
  origin: [
    'https://app.interaedu.com',
    'https://admin.interaedu.com',
    // Desenvolvimento
    'http://localhost:3000',
    'http://localhost:8080',
  ],
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type', 'X-Request-ID', 'X-Idempotency-Key'],
  credentials: true,
  maxAge: 86400, // 24 horas
}
```

---

## 9. Security Headers

Todas as respostas incluem os seguintes headers de segurança:

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

## 10. Modelo de Ameaças (Threat Model)

| Ameaça | Mitigação |
|:---|:---|
| Credential stuffing (preenchimento automático com credenciais vazadas) | Rate limiting por IP + bloqueio de conta |
| Força bruta no OTP | Limite de 5 tentativas + bloqueio de 15 minutos |
| Roubo de token de sessão | Access tokens de curta duração (15 min) + rotação de refresh token |
| Replay attack | Invalidação em família do refresh token |
| XSS (Cross-Site Scripting) | Validação de entrada + headers CSP |
| SQL Injection | Queries parametrizadas via TypeORM |
| CSRF | Cookies SameSite + autenticação baseada em token |
| Vazamento de dados | RLS no banco de dados + máscara de privacidade na camada de aplicação |
| Upload de arquivos maliciosos | Validação por magic bytes + varredura antivírus (prevista para versões futuras) |
| DDoS | Rate limiting + WAF (em produção) |
