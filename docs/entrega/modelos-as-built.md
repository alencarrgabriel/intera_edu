# Modelos de persistência As-Built

Extraído das entidades TypeORM. A anotação Entity e as propriedades abaixo identificam a estrutura entregue; decorators de coluna, índices, relações e nulabilidade de banco constam dos arquivos vinculados. Não se trata de um dump do banco em execução.

Os schemas são criados por `backend/scripts/init-db.sql`. Em desenvolvimento, TypeORM usa synchronize; não existe comprovação de migrações de produção completas.

## AuditLog

[backend/shared/src/audit/audit-log.entity.ts](../../backend/shared/src/audit/audit-log.entity.ts) — `@Entity({ schema: 'audit', name: 'audit_logs' })`

```typescript
id: string
userId: string | null
method: string
path: string
targetType: string | null
targetId: string | null
statusCode: number
ipAddress: string | null
metadata: any
createdAt: Date
```

## ConsentRecord

[backend/auth-service/src/database/entities/consent-record.entity.ts](../../backend/auth-service/src/database/entities/consent-record.entity.ts) — `@Entity({ schema: 'auth', name: 'consent_records' })`

```typescript
id: string
userId: string
consentType: string
version: string
acceptedAt: Date
ipAddress: string
userAgent: string
revokedAt: Date | null
```

## Institution

[backend/auth-service/src/database/entities/institution.entity.ts](../../backend/auth-service/src/database/entities/institution.entity.ts) — `@Entity({ schema: 'auth', name: 'institutions' })`

```typescript
id: string
name: string
slug: string
domains: string[]
isVerified: boolean
logoUrl: string
createdAt: Date
updatedAt: Date
```

## RefreshToken

[backend/auth-service/src/database/entities/refresh-token.entity.ts](../../backend/auth-service/src/database/entities/refresh-token.entity.ts) — `@Entity({ schema: 'auth', name: 'refresh_tokens' })`

```typescript
id: string
userId: string
tokenHash: string
deviceInfo: Record<string, unknown>
expiresAt: Date
createdAt: Date
revokedAt: Date
```

## UserCredential

[backend/auth-service/src/database/entities/user-credential.entity.ts](../../backend/auth-service/src/database/entities/user-credential.entity.ts) — `@Entity({ schema: 'auth', name: 'user_credentials' })`

```typescript
id: string
email: string
passwordHash: string | null
googleId: string | null
institutionId: string
status: string
lastLoginAt: Date
createdAt: Date
updatedAt: Date
deletedAt: Date
```

## Connection

[backend/profile-service/src/database/entities/connection.entity.ts](../../backend/profile-service/src/database/entities/connection.entity.ts) — `@Entity({ schema: 'profile', name: 'connections' })`

```typescript
id: string
requesterId: string
addresseeId: string
status: ConnectionStatus
requestedAt: Date
respondedAt?: Date | null
```

## Skill

[backend/profile-service/src/database/entities/skill.entity.ts](../../backend/profile-service/src/database/entities/skill.entity.ts) — `@Entity({ schema: 'profile', name: 'skills' })`

```typescript
id: string
name: string
slug: string
category: string
createdAt: Date
```

## UserBlock

[backend/profile-service/src/database/entities/user-block.entity.ts](../../backend/profile-service/src/database/entities/user-block.entity.ts) — `@Entity({ schema: 'profile', name: 'user_blocks' })`

```typescript
id: string
blockerId: string
blockedId: string
createdAt: Date
```

## UserLink

[backend/profile-service/src/database/entities/user-link.entity.ts](../../backend/profile-service/src/database/entities/user-link.entity.ts) — `@Entity({ schema: 'profile', name: 'user_links' })`

```typescript
id: string
userId: string
linkType: string
url: string
createdAt: Date
```

## UserProfile

[backend/profile-service/src/database/entities/user-profile.entity.ts](../../backend/profile-service/src/database/entities/user-profile.entity.ts) — `@Entity({ schema: 'profile', name: 'users' })`

```typescript
id: string
institutionId: string
email?: string | null
handle?: string | null
fullName: string
bio?: string | null
course?: string | null
period?: number | null
privacyLevel: PrivacyLevel
avatarUrl?: string | null
createdAt: Date
updatedAt: Date
deletedAt?: Date | null
```

## UserSkill

[backend/profile-service/src/database/entities/user-skill.entity.ts](../../backend/profile-service/src/database/entities/user-skill.entity.ts) — `@Entity({ schema: 'profile', name: 'user_skills' })`

```typescript
userId: string
skillId: string
user?: UserProfile
skill?: Skill
```

## BookmarkEntity

[backend/feed-service/src/database/entities/bookmark.entity.ts](../../backend/feed-service/src/database/entities/bookmark.entity.ts) — `@Entity({ schema: 'feed', name: 'bookmarks' })`

```typescript
id: string
userId: string
postId: string
createdAt: Date
```

## CommentEntity

[backend/feed-service/src/database/entities/comment.entity.ts](../../backend/feed-service/src/database/entities/comment.entity.ts) — `@Entity({ schema: 'feed', name: 'comments' })`

```typescript
id: string
postId: string
userId: string
parentCommentId?: string | null
content: string
createdAt: Date
deletedAt?: Date | null
```

## DisciplineGroupEntity

[backend/feed-service/src/database/entities/discipline-group.entity.ts](../../backend/feed-service/src/database/entities/discipline-group.entity.ts) — `@Entity({ schema: 'feed', name: 'discipline_groups' })`

```typescript
id: string
disciplineId: string
institutionId: string
name: string
description?: string | null
coverUrl?: string | null
memberCount: number
postCount: number
materialCount: number
createdBy: string
createdAt: Date
```

## DisciplineEntity

[backend/feed-service/src/database/entities/discipline.entity.ts](../../backend/feed-service/src/database/entities/discipline.entity.ts) — `@Entity({ schema: 'feed', name: 'disciplines' })`

```typescript
id: string
institutionId: string
code: string
name: string
period?: string | null
description?: string | null
createdAt: Date
```

## GroupMemberEntity

[backend/feed-service/src/database/entities/group-member.entity.ts](../../backend/feed-service/src/database/entities/group-member.entity.ts) — `@Entity({ schema: 'feed', name: 'discipline_group_members' })`

```typescript
id: string
groupId: string
userId: string
role: GroupRole
joinedAt: Date
```

## MaterialRatingEntity

[backend/feed-service/src/database/entities/material-rating.entity.ts](../../backend/feed-service/src/database/entities/material-rating.entity.ts) — `@Entity({ schema: 'feed', name: 'material_ratings' })`

```typescript
id: string
materialId: string
userId: string
rating: number
createdAt: Date
updatedAt: Date
```

## MaterialEntity

[backend/feed-service/src/database/entities/material.entity.ts](../../backend/feed-service/src/database/entities/material.entity.ts) — `@Entity({ schema: 'feed', name: 'materials' })`

```typescript
id: string
groupId: string
uploaderId: string
title: string
description?: string | null
fileUrl: string
fileMime?: string | null
fileSize?: number | null
kind: MaterialKind
downloadCount: number
ratingSum: number
ratingCount: number
createdAt: Date
deletedAt?: Date | null
```

## PostMentionEntity

[backend/feed-service/src/database/entities/post-mention.entity.ts](../../backend/feed-service/src/database/entities/post-mention.entity.ts) — `@Entity({ schema: 'feed', name: 'mentions' })`

```typescript
id: string
source: MentionSource
sourceId: string
mentionedUserId: string
authorId: string
createdAt: Date
```

## PostTagEntity

[backend/feed-service/src/database/entities/post-tag.entity.ts](../../backend/feed-service/src/database/entities/post-tag.entity.ts) — `@Entity({ schema: 'feed', name: 'post_tags' })`

```typescript
id: string
postId: string
tagId: string
createdAt: Date
```

## PostEntity

[backend/feed-service/src/database/entities/post.entity.ts](../../backend/feed-service/src/database/entities/post.entity.ts) — `@Entity({ schema: 'feed', name: 'posts' })`

```typescript
id: string
authorId: string
institutionId: string
groupId?: string | null
content: string
scope: PostScope
mediaUrls?: string[] | null
reactionCount: number
commentCount: number
createdAt: Date
updatedAt: Date
deletedAt?: Date | null
```

## ReactionEntity

[backend/feed-service/src/database/entities/reaction.entity.ts](../../backend/feed-service/src/database/entities/reaction.entity.ts) — `@Entity({ schema: 'feed', name: 'reactions' })`

```typescript
id: string
postId: string
userId: string
reactionType: ReactionType
createdAt: Date
```

## StoryViewEntity

[backend/feed-service/src/database/entities/story-view.entity.ts](../../backend/feed-service/src/database/entities/story-view.entity.ts) — `@Entity({ schema: 'feed', name: 'story_views' })`

```typescript
id: string
storyId: string
userId: string
viewedAt: Date
```

## StoryEntity

[backend/feed-service/src/database/entities/story.entity.ts](../../backend/feed-service/src/database/entities/story.entity.ts) — `@Entity({ schema: 'feed', name: 'stories' })`

```typescript
id: string
authorId: string
institutionId: string
mediaUrl?: string | null
mediaMime?: string | null
caption?: string | null
viewCount: number
createdAt: Date
expiresAt: Date
```

## TagFollowEntity

[backend/feed-service/src/database/entities/tag-follow.entity.ts](../../backend/feed-service/src/database/entities/tag-follow.entity.ts) — `@Entity({ schema: 'feed', name: 'tag_follows' })`

```typescript
id: string
userId: string
tagId: string
createdAt: Date
```

## TagEntity

[backend/feed-service/src/database/entities/tag.entity.ts](../../backend/feed-service/src/database/entities/tag.entity.ts) — `@Entity({ schema: 'feed', name: 'tags' })`

```typescript
id: string
slug: string
name: string
postCount: number
followerCount: number
createdAt: Date
```

## Report

[backend/feed-service/src/reports/report.entity.ts](../../backend/feed-service/src/reports/report.entity.ts) — `@Entity({ schema: 'feed', name: 'reports' })`

```typescript
id: string
reporterId: string
targetType: string
targetId: string
reason: string
description: string | null
status: string
createdAt: Date
resolvedAt: Date | null
resolvedBy: string | null
```

## ChatMember

[backend/messaging-service/src/database/entities/chat-member.entity.ts](../../backend/messaging-service/src/database/entities/chat-member.entity.ts) — `@Entity({ schema: 'messaging', name: 'chat_members' })`

```typescript
chatId: string
userId: string
role: MemberRole
joinedAt: Date
chat: Chat
```

## Chat

[backend/messaging-service/src/database/entities/chat.entity.ts](../../backend/messaging-service/src/database/entities/chat.entity.ts) — `@Entity({ schema: 'messaging', name: 'chats' })`

```typescript
id: string
type: ChatType
name?: string | null
createdBy: string
createdAt: Date
updatedAt: Date
members: ChatMember[]
messages: Message[]
```

## Message

[backend/messaging-service/src/database/entities/message.entity.ts](../../backend/messaging-service/src/database/entities/message.entity.ts) — `@Entity({ schema: 'messaging', name: 'messages' })`

```typescript
id: string
chatId: string
senderId: string
content: string
fileUrl?: string | null
createdAt: Date
deletedAt?: Date | null
chat: Chat
```

## Notification

[backend/messaging-service/src/notifications/notification.entity.ts](../../backend/messaging-service/src/notifications/notification.entity.ts) — `@Entity({ schema: 'messaging', name: 'notifications' })`

```typescript
id: string
userId: string
type: string
title: string
body: string | null
payload: any
readAt: Date | null
createdAt: Date
```
