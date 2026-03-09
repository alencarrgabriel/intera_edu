# Modelo de Dados - InteraEdu

Este documento descreve a estrutura lógica do banco de dados relacional (PostgreSQL) para suportar o MVP.

## 1. Entidades Principais

### `institutions` (Tenants)
| Campo | Tipo | Descrição |
|:---|:---|:---|
| `id` | UUID (PK) | Identificador único da IES. |
| `name` | String | Nome oficial (ex: USP). |
| `domain` | String | Domínio de e-mail (ex: @usp.br). |
| `is_verified` | Boolean | Se a instituição foi validada pelo sistema. |

### `users`
| Campo | Tipo | Descrição |
|:---|:---|:---|
| `id` | UUID (PK) | ID global do usuário. |
| `institution_id` | UUID (FK) | Vínculo com a IES. |
| `full_name` | String | Nome completo. |
| `email` | String (Unique) | E-mail institucional verificado. |
| `course` | String | Curso atual (ex: Engenharia). |
| `period` | Integer | Semestre/Ano atual. |
| `skills` | JSONB/Array | Lista de tags (ex: ["Python", "UX"]). |
| `privacy_level` | Enum | "Public", "LocalOnly", "Private". |
| `lgpd_consent` | Boolean | Status do aceite legal. |

### `connections`
| Campo | Tipo | Descrição |
|:---|:---|:---|
| `id` | UUID | |
| `user_a_id` | FK | Remetente. |
| `user_b_id` | FK | Destinatário. |
| `status` | Enum | "Pending", "Accepted", "Blocked". |

### `posts`
| Campo | Tipo | Descrição |
|:---|:---|:---|
| `id` | UUID | |
| `author_id` | FK | Autor do post. |
| `institution_id` | FK | Para filtro de Feed Local. |
| `content` | Text | Conteúdo da postagem. |
| `scope` | Enum | "Local", "Global". |
| `created_at` | Timestamp | |

### `messages`
| Campo | Tipo | Descrição |
|:---|:---|:---|
| `id` | UUID | |
| `sender_id` | FK | |
| `chat_id` | UUID (FK) | Referência ao grupo ou chat 1:1. |
| `content` | Text | |
| `file_url` | String | Link para anexo (S3). |

---

## 2. Relacionamentos
*   **User -> Institution**: M-1 (Um usuário pertence a uma IES).
*   **User -> Post**: 1-M (Um usuário faz vários posts).
*   **Post -> Institution**: M-1 (O post é vinculado à IES do autor para o feed local).
*   **Direct Message**: Tabela de `chats` (UUID) que vincula dois ou mais usuários.
