# InteraEdu — API Design

**Version:** 2.0
**Date:** March 2026
**Base URL:** `https://api.interaedu.com/api/v1`

---

## 1. Design Principles

| Principle | Implementation |
|:---|:---|
| **RESTful** | Resources as nouns, HTTP verbs for actions |
| **Versioned** | URL path versioning (`/api/v1/`) |
| **Paginated** | Cursor-based pagination for all list endpoints |
| **Consistent Errors** | Standard error envelope on all responses |
| **Authenticated** | `Authorization: Bearer <JWT>` on all private endpoints |
| **Content Type** | `application/json` for request/response bodies |
| **Idempotent** | PUT/DELETE are idempotent; POST uses `Idempotency-Key` header where needed |

---

## 2. Authentication Endpoints

### `POST /api/v1/auth/register`
Start registration flow. Validates email domain and sends OTP.

**Request:**
```json
{
  "email": "ana@aluno.ufmg.br"
}
```

**Response:** `202 Accepted`
```json
{
  "message": "OTP sent to your institutional email",
  "expires_in_seconds": 600
}
```

**Errors:** `422` (invalid email format), `403` (domain not approved), `429` (rate limited)

---

### `POST /api/v1/auth/verify-otp`
Verify OTP code. Returns a temporary token for completing registration.

**Request:**
```json
{
  "email": "ana@aluno.ufmg.br",
  "code": "482951"
}
```

**Response:** `200 OK`
```json
{
  "temporary_token": "eyJ...",
  "expires_in_seconds": 900
}
```

**Errors:** `401` (invalid code), `410` (code expired), `429` (too many attempts — locked for 15 min)

---

### `POST /api/v1/auth/complete-registration`
Complete registration with password and profile data.

**Headers:** `Authorization: Bearer <temporary_token>`

**Request:**
```json
{
  "password": "SecureP@ss123",
  "full_name": "Ana Silva",
  "course": "Computer Science",
  "period": 3,
  "skill_ids": ["uuid-python", "uuid-react"],
  "consent": {
    "terms_version": "v1.0",
    "privacy_version": "v1.0"
  }
}
```

**Response:** `201 Created`
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
Email + password login.

**Request:**
```json
{
  "email": "ana@aluno.ufmg.br",
  "password": "SecureP@ss123"
}
```

**Response:** `200 OK`
```json
{
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Errors:** `401` (invalid credentials), `403` (account suspended), `429` (rate limited)

---

### `POST /api/v1/auth/refresh`
Rotate refresh token and issue new access token.

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:** `200 OK`
```json
{
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 900
  }
}
```

**Errors:** `401` (token revoked or expired)

---

### `POST /api/v1/auth/logout`
Revoke the current refresh token.

**Headers:** `Authorization: Bearer <access_token>`

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:** `204 No Content`

---

### `POST /api/v1/auth/forgot-password`
Initiate password reset via OTP.

**Request:**
```json
{
  "email": "ana@aluno.ufmg.br"
}
```

**Response:** `202 Accepted`

---

### `POST /api/v1/auth/reset-password`
Complete password reset.

**Request:**
```json
{
  "email": "ana@aluno.ufmg.br",
  "code": "482951",
  "new_password": "NewSecureP@ss456"
}
```

**Response:** `200 OK`

---

## 3. Profile Endpoints

### `GET /api/v1/users/me`
Get the authenticated user's profile.

**Response:** `200 OK`
```json
{
  "id": "uuid-user",
  "email": "ana@aluno.ufmg.br",
  "full_name": "Ana Silva",
  "bio": "CS student passionate about ML",
  "course": "Computer Science",
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
Update own profile. Partial updates only.

**Request:**
```json
{
  "bio": "Updated bio",
  "period": 4,
  "skill_ids": ["uuid-python", "uuid-ml", "uuid-react"],
  "privacy_level": "public"
}
```

**Response:** `200 OK` (returns updated profile)

---

### `DELETE /api/v1/users/me`
Request account deletion (LGPD right to erasure).

**Request:**
```json
{
  "password": "SecureP@ss123",
  "confirmation": "DELETE MY ACCOUNT"
}
```

**Response:** `202 Accepted`
```json
{
  "message": "Account deletion scheduled. Data will be anonymized within 30 days.",
  "deletion_scheduled_at": "2026-04-15T00:00:00Z"
}
```

---

### `GET /api/v1/users/me/data-export`
Request LGPD data export.

**Response:** `202 Accepted`
```json
{
  "message": "Data export is being generated. You will receive a download link via email within 48 hours.",
  "request_id": "uuid-export-request"
}
```

---

### `GET /api/v1/users/:id`
View another user's public profile. Respects privacy masking.

**Response:** `200 OK` (same structure as `/me`, but filtered by privacy_level)

**Errors:** `404` (user not found or not visible due to privacy settings)

---

### `GET /api/v1/users/search`
Search users with filters and full-text search.

**Query Parameters:**

| Param | Type | Description |
|:---|:---|:---|
| `q` | string | Full-text search on name |
| `skill` | string | Skill slug (e.g., `python`) |
| `institution` | string | Institution slug (e.g., `usp`) |
| `course` | string | Course name filter |
| `cursor` | string | Pagination cursor |
| `limit` | integer | Items per page (default: 20, max: 50) |

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid-user",
      "full_name": "Carlos Lima",
      "course": "Biotechnology",
      "institution": { "id": "uuid-usp", "name": "USP" },
      "skills": [
        { "id": "uuid-ml", "name": "Machine Learning" }
      ],
      "avatar_url": "https://cdn.interaedu.com/avatars/uuid.jpg"
    }
  ],
  "pagination": {
    "cursor": "encoded-cursor-string",
    "has_more": true,
    "total_count": 142
  }
}
```

---

## 4. Connection Endpoints

### `POST /api/v1/connections`
Send a connection request.

**Request:**
```json
{
  "addressee_id": "uuid-target-user",
  "message": "Hi! I'd love to collaborate on our ML project."
}
```

**Response:** `201 Created`

**Errors:** `409` (request already exists), `403` (blocked by target), `404` (user not found)

---

### `GET /api/v1/connections`
List connections and pending requests.

**Query Parameters:**

| Param | Type | Description |
|:---|:---|:---|
| `status` | string | `pending`, `accepted` |
| `direction` | string | `sent`, `received` (only for `pending`) |
| `cursor` | string | Pagination cursor |

---

### `PATCH /api/v1/connections/:id`
Accept or reject a connection request.

**Request:**
```json
{
  "action": "accept"
}
```

**Response:** `200 OK`

---

### `DELETE /api/v1/connections/:id`
Remove an existing connection.

**Response:** `204 No Content`

---

## 5. Feed Endpoints

### `GET /api/v1/posts`
Get the feed.

**Query Parameters:**

| Param | Type | Description |
|:---|:---|:---|
| `scope` | string | `local` or `global` (default: `local`) |
| `cursor` | string | Pagination cursor |
| `limit` | integer | Items per page (default: 20, max: 50) |

**Response:** `200 OK`
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
      "content": "Looking for a partner to work on NLP research!",
      "scope": "global",
      "media_urls": [],
      "reaction_count": 5,
      "comment_count": 2,
      "user_reaction": "like",
      "created_at": "2026-03-15T10:30:00Z"
    }
  ],
  "pagination": {
    "cursor": "encoded-cursor",
    "has_more": true
  }
}
```

---

### `POST /api/v1/posts`
Create a new post.

**Request:**
```json
{
  "content": "Looking for collaborators on my research project about...",
  "scope": "global",
  "media_urls": ["https://s3.../file.pdf"]
}
```

**Response:** `201 Created`

---

### `DELETE /api/v1/posts/:id`
Soft-delete own post.

**Response:** `204 No Content`

**Errors:** `403` (not the author), `404` (not found)

---

### `POST /api/v1/posts/:id/reactions`
Add a reaction.

**Request:**
```json
{
  "type": "insightful"
}
```

**Response:** `201 Created`

**Errors:** `409` (already reacted)

---

### `GET /api/v1/posts/:id/comments`
List comments on a post (cursor-paginated).

---

### `POST /api/v1/posts/:id/comments`
Add a comment.

**Request:**
```json
{
  "content": "Great idea! I'm working on something similar.",
  "parent_comment_id": null
}
```

**Response:** `201 Created`

---

## 6. Messaging Endpoints

### `GET /api/v1/chats`
List user's active chats.

**Query Parameters:**

| Param | Type | Description |
|:---|:---|:---|
| `type` | string | `direct`, `group`, or omit for all |
| `cursor` | string | Pagination cursor |

**Response:** `200 OK`
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
        "content": "Sure, let's meet tomorrow!",
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
Create a new chat.

**Request (Direct):**
```json
{
  "type": "direct",
  "participant_ids": ["uuid-user-b"]
}
```

**Request (Group):**
```json
{
  "type": "group",
  "name": "ML Study Group",
  "description": "Weekly machine learning discussions",
  "topic_tags": ["machine-learning", "python"],
  "participant_ids": ["uuid-a", "uuid-b", "uuid-c"]
}
```

**Response:** `201 Created`

**Errors:** `409` (direct chat already exists), `403` (not connected to participant)

---

### `GET /api/v1/chats/:id/messages`
Get paginated message history.

**Query Parameters:**

| Param | Type | Description |
|:---|:---|:---|
| `cursor` | string | Message cursor (before this message) |
| `limit` | integer | Messages per page (default: 50) |

---

### `POST /api/v1/chats/:id/messages`
Send a message (HTTP fallback for WebSocket).

**Request:**
```json
{
  "content": "Hello! Want to work together?",
  "file_url": null
}
```

**Response:** `201 Created`

---

### `POST /api/v1/upload/presign`
Get a presigned URL for file upload.

**Request:**
```json
{
  "file_name": "research_paper.pdf",
  "content_type": "application/pdf",
  "size_bytes": 2048576
}
```

**Response:** `200 OK`
```json
{
  "upload_url": "https://s3.amazonaws.com/...",
  "file_url": "https://cdn.interaedu.com/files/uuid-file.pdf",
  "expires_in_seconds": 3600
}
```

**Errors:** `413` (file too large), `415` (unsupported type)

---

## 7. Skill Endpoints

### `GET /api/v1/skills`
List all skills.

**Query Parameters:** `category`, `cursor`, `limit`

### `GET /api/v1/skills/search?q=pyth`
Search skills by name prefix.

---

## 8. Notification Endpoints

### `GET /api/v1/notifications`
Get user's notifications (cursor-paginated).

### `PATCH /api/v1/notifications/:id/read`
Mark a notification as read.

### `PATCH /api/v1/notifications/read-all`
Mark all notifications as read.

---

## 9. Admin Endpoints

### `POST /api/v1/admin/institutions`
Register a new institution.

### `PATCH /api/v1/admin/institutions/:id`
Update institution settings.

### `GET /api/v1/admin/reports`
List pending abuse reports.

### `PATCH /api/v1/admin/reports/:id`
Resolve a report.

---

## 10. Standard Error Response

All error responses follow a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email domain is not an approved educational institution.",
    "status": 403,
    "details": [
      {
        "field": "email",
        "message": "Domain @gmail.com is not in the approved list"
      }
    ],
    "request_id": "uuid-request-id",
    "timestamp": "2026-03-15T10:30:00Z"
  }
}
```

### Error Codes

| HTTP Status | Code | Description |
|:---|:---|:---|
| 400 | `BAD_REQUEST` | Malformed request body |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions or domain not approved |
| 404 | `NOT_FOUND` | Resource does not exist or is hidden by privacy |
| 409 | `CONFLICT` | Duplicate resource (e.g., connection already exists) |
| 410 | `GONE` | Resource expired (e.g., OTP) |
| 413 | `PAYLOAD_TOO_LARGE` | File exceeds size limit |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | File type not allowed |
| 422 | `VALIDATION_ERROR` | Request validation failed |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Unexpected server error |
| 503 | `SERVICE_UNAVAILABLE` | Downstream service unavailable |

---

## 11. Common Headers

### Request Headers

| Header | Required | Description |
|:---|:---|:---|
| `Authorization` | Yes* | `Bearer <JWT>` (* except public endpoints) |
| `Content-Type` | Yes | `application/json` |
| `Accept-Language` | No | `pt-BR` (default), `en` |
| `X-Idempotency-Key` | No | UUID for POST idempotency |

### Response Headers

| Header | Description |
|:---|:---|
| `X-Request-ID` | Unique request identifier for tracing |
| `X-RateLimit-Limit` | Max requests in current window |
| `X-RateLimit-Remaining` | Remaining requests in current window |
| `X-RateLimit-Reset` | Unix timestamp when the window resets |
