# InteraEdu — Estratégia de Escalabilidade

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Roadmap de Escalabilidade

| Etapa | Usuários | Arquitetura | Ações Principais |
|:---|:---|:---|:---|
| **MVP** | 0 – 10K | Uma instância por serviço, PostgreSQL compartilhado | Docker Compose, cache básico com Redis |
| **Crescimento** | 10K – 100K | Múltiplas instâncias por serviço, réplicas de leitura | Escalamento horizontal de pods, connection pooling, índice de pesquisa |
| **Escala** | 100K – 1M+ | Kubernetes completo, banco de dados dedicado por serviço | Sharding de banco, CDN, cluster Elasticsearch |

---

## 2. Estratégia de Cache do Feed

### 2.1 Arquitetura de Cache

```text
Requisição do Cliente
     │
     ▼
┌──────────┐    Chave de cache: feed:{scope}:{institution_id}:{cursor_hash}
│ Feed     │──────────────────────────────► Cache Redis
│ Service  │                                    │
│          │◄───────────────────────────────────┤ HIT → Retorna feed em cache
│          │                                    │ MISS ↓
│          │    Query no PostgreSQL              │
│          │──────────────────────────────► PostgreSQL
│          │◄──────────────────────────────     │
│          │    Processa resultado               │
│          │    Armazena em cache (TTL: 60s) ──► Cache Redis
│          │                                    │
│          │    Retorna para o cliente          │
└──────────┘
```

### 2.2 Chaves de Cache

| Padrão de Chave | TTL | Invalidação |
|:---|:---|:---|
| `feed:local:{institution_id}:{cursor}` | 60s | Ao criar/deletar post (`post.created/deleted`) naquela instituição |
| `feed:global:{institution_id}:{cursor}` | 60s | Ao criar/deletar qualquer post |
| `profile:{user_id}` | 300s | Ao atualizar perfil (`profile.updated`) |
| `user:connections:{user_id}` | 600s | Ao aceitar/remover conexão |
| `skills:taxonomy` | 3600s | Ao atualizar habilidades pelo admin |
| `institution:domains` | 3600s | Ao atualizar domínios pelo admin |

### 2.3 Cache Warming (Pré-aquecimento)
- Na inicialização do serviço, pré-carrega a taxonomia de habilidades e os domínios institucionais no Redis.
- Para instituições populares (top 10 por número de usuários), o feed local é pré-gerado e armazenado em cache.

---

## 3. Mapa de Uso do Redis

| Caso de Uso | Estrutura de Dados Redis | Detalhes |
|:---|:---|:---|
| **Cache do feed** | String (JSON) | Páginas de feed serializadas; expiração por TTL |
| **Sessão/Armazenamento de OTP** | String | Códigos OTP com TTL de 10 minutos |
| **Rate limiting** | Sorted Set (sliding window) | Score = timestamp, membro = request ID |
| **Pub/Sub do WebSocket** | Canais Pub/Sub | Um canal por sala de chat: `chat:{chat_id}` |
| **Presença online** | Set | Set `online_users` com limpeza periódica |
| **Blacklist de tokens** | Set | `blacklisted_tokens` para revogação emergencial |
| **Indicadores de digitação** | String (com TTL) | `typing:{chat_id}:{user_id}` com TTL de 5 segundos |

### 3.1 Estimativa de Memória do Redis (100K usuários)

| Dado | Tamanho Estimado |
|:---|:---|
| Cache do feed (top 1000 feeds) | ~50 MB |
| Sessões ativas / OTPs | ~5 MB |
| Janelas de rate limiting | ~10 MB |
| Set de presença online | ~2 MB |
| Blacklist de tokens | ~1 MB |
| **Total** | **~70 MB** |

---

## 4. Estratégia de Filas de Mensagens

### 4.1 BullMQ (Fila de Jobs com Redis)

O BullMQ gerencia jobs assíncronos em background:

| Fila | Jobs | Prioridade | Concorrência |
|:---|:---|:---|:---|
| `email` | Envio de OTP, notificações, links de exportação de dados | Alta | 5 workers |
| `feed-invalidation` | Invalidação de cache ao alterar posts | Alta | 3 workers |
| `data-export` | Geração de exportação de dados (LGPD) | Baixa | 1 worker |
| `cleanup` | Purga de OTPs expirados, tokens revogados e dados com soft delete | Baixa | 1 worker |
| `notifications` | Envio de notificações push (FCM) | Média | 3 workers |
| `anonymization` | Cascata de anonimização ao deletar conta | Baixa | 1 worker |

### 4.2 Estratégia de Retentativas

| Fila | Máx. Retentativas | Backoff | Dead Letter |
|:---|:---|:---|:---|
| `email` | 3 | Exponencial (1s, 4s, 16s) | Sim |
| `feed-invalidation` | 2 | Fixo (500ms) | Não (best effort) |
| `data-export` | 3 | Exponencial (30s, 120s, 480s) | Sim |
| `notifications` | 2 | Exponencial (1s, 4s) | Sim |
| `anonymization` | 5 | Exponencial (60s, 240s, ...) | Sim (com alertas) |

### 4.3 Migração Futura para Apache Kafka
Quando o sistema processar mais de 10K eventos/segundo (estimado em ~500K MAU), migrar de BullMQ para Kafka para obter:
- Capacidade de event sourcing
- Suporte a múltiplos consumidores (mesmo evento consumido por vários serviços)
- Replay de eventos para depuração
- Maior throughput

---

## 5. Estratégia de Indexação de Pesquisa

### 5.1 Fase 1 (MVP): PostgreSQL Nativo

```sql
-- Busca de usuários: GIN + tsvector
SELECT u.id, u.full_name, u.course, u.institution_id
FROM profile.users u
JOIN profile.user_skills us ON u.id = us.user_id
JOIN profile.skills s ON us.skill_id = s.id
WHERE s.slug = 'python'
  AND u.institution_id = 'uuid-usp'
  AND u.privacy_level = 'public'
  AND u.deleted_at IS NULL
ORDER BY u.created_at DESC
LIMIT 20;

-- Busca por nome em texto completo
SELECT * FROM profile.users
WHERE to_tsvector('portuguese', full_name) @@ plainto_tsquery('portuguese', 'Ana Silva')
  AND deleted_at IS NULL;
```

Performance esperada: < 100ms para até 500K usuários com índices adequados.

### 5.2 Fase 2 (Escala): Elasticsearch

Quando a busca em texto completo do PostgreSQL se tornar um gargalo (> 500K usuários ou queries complexas):

```text
PostgreSQL ──(CDC via Debezium)──► Kafka ──► Elasticsearch
                                              │
API Query ──────────────────────────────────► Cluster ES
                                              │
                                        Retorna resultados
```

**Mapeamentos de índice do Elasticsearch:**

```json
{
  "users": {
    "properties": {
      "full_name": { "type": "text", "analyzer": "portuguese" },
      "skills": { "type": "keyword" },
      "course": { "type": "keyword" },
      "institution_id": { "type": "keyword" },
      "privacy_level": { "type": "keyword" }
    }
  },
  "posts": {
    "properties": {
      "content": { "type": "text", "analyzer": "portuguese" },
      "institution_id": { "type": "keyword" },
      "scope": { "type": "keyword" },
      "created_at": { "type": "date" }
    }
  }
}
```

---

## 6. Escalamento Horizontal

### 6.1 Metas de Escalamento por Serviço

| Serviço | Mín. Réplicas | Máx. Réplicas | Gatilho de Escalamento |
|:---|:---|:---|:---|
| Gateway | 2 | 10 | CPU > 70% ou RPS > 500/instância |
| Auth Service | 2 | 5 | CPU > 70% |
| Profile Service | 2 | 8 | CPU > 70% ou RPS > 300/instância |
| Feed Service | 2 | 10 | CPU > 70% ou latência p95 > 1s |
| Messaging Service | 2 | 15 | Conexões WebSocket > 5K/instância |

### 6.2 Escalamento do Banco de Dados

| Fase | Estratégia |
|:---|:---|
| MVP | Instância única do PostgreSQL (schemas compartilhados) |
| Crescimento | Réplicas de leitura para Profile e Feed |
| Escala | Instâncias PostgreSQL separadas por serviço |
| Empresa | PgBouncer para connection pooling + Citus para sharding horizontal |

### 6.3 Escalamento do WebSocket

```text
                   ┌─────── Load Balancer (sticky sessions) ──────┐
                   │                    │                          │
          ┌────────▼──┐       ┌────────▼──┐              ┌───────▼───┐
          │ Messaging │       │ Messaging │              │ Messaging │
          │ Instância1│       │ Instância2│              │ InstânciaN│
          └────┬──────┘       └────┬──────┘              └────┬──────┘
               │                   │                          │
               └───────────── Redis Pub/Sub ──────────────────┘
                            (adaptador de fan-out)
```

- Socket.IO com `@socket.io/redis-adapter` para retransmissão de mensagens entre instâncias.
- Sticky sessions no load balancer (baseado no hash do ID do usuário) para minimizar o tráfego no Redis pub/sub.
- Connection draining ao escalar para baixo (migração graceful de WebSockets).

---

## 7. CDN e Assets Estáticos

| Tipo de Asset | Armazenamento | CDN |
|:---|:---|:---|
| Avatares de usuário | S3 | CloudFront / Cloud CDN |
| Mídia de posts (imagens, PDFs) | S3 | CloudFront / Cloud CDN |
| Assets do app (Flutter web) | S3 | CloudFront / Cloud CDN |

**Política de cache:** Assets imutáveis (arquivos enviados por usuário) armazenados em cache indefinidamente com nomes únicos baseados em UUID. Assets dinâmicos (avatares) com TTL de 1 hora (`Cache-Control: max-age=3600`).

---

## 8. Benchmarks de Performance (Alvos)

| Operação | Alvo (p95) | Ponto de Medição |
|:---|:---|:---|
| Login | < 500ms | Cliente → Gateway → Auth → Resposta |
| Carregar feed local (com cache) | < 200ms | Gateway → Feed → Redis → Resposta |
| Carregar feed local (sem cache) | < 2000ms | Gateway → Feed → PostgreSQL → Resposta |
| Busca de usuário | < 1000ms | Gateway → Profile → PostgreSQL → Resposta |
| Enviar mensagem (WebSocket) | < 300ms | Cliente → Messaging → Persistir + Pub/Sub → Entrega |
| Enviar mensagem (fallback HTTP) | < 1000ms | Cliente → Gateway → Messaging → Resposta |
| Upload de arquivo (10MB) | < 5000ms | Cliente → Upload direto para S3 via URL pré-assinada |

---

## 9. Recuperação de Desastres

| Componente | RPO | RTO | Estratégia |
|:---|:---|:---|:---|
| PostgreSQL | 1 hora | 4 horas | Backups automáticos point-in-time (backup completo diário + WAL archiving) |
| Redis | Perda aceitável | 5 minutos | Persistência Redis (snapshots RDB a cada 5 min) + reconstrução a partir do banco |
| Arquivos S3 | 0 (durabilidade garantida) | Imediato | Replicação S3 entre regiões |
| Código dos serviços | 0 | 15 minutos | Re-deploy do contêiner a partir do registry |

**Calendário de backups:**
- PostgreSQL: Backup completo diário às 03:00 UTC + WAL archiving contínuo.
- Redis: Snapshot RDB a cada 5 minutos (perda de dados aceitável para cache).
- S3: Durabilidade de 11 noves incorporada.
