# InteraEdu — Software Requirements Specification (SRS)

**Version:** 2.0
**Date:** March 2026
**Status:** Production Architecture

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements for InteraEdu, an academic networking platform enabling cross-university collaboration. It serves as the single source of truth for development, testing, and product validation.

### 1.2 Scope
InteraEdu is a **standalone, cloud-native, multi-tenant** platform. It does not integrate with university ERPs. Authentication is based on institutional email domain validation. The MVP targets Brazilian universities operating under LGPD regulations.

### 1.3 Definitions

| Term | Definition |
|:---|:---|
| **IES** | Instituição de Ensino Superior (Higher Education Institution) |
| **Tenant** | A registered IES within the platform |
| **OTP** | One-Time Password for email verification |
| **Privacy Masking** | Logic that controls cross-institution profile visibility |
| **Force Exploration** | Algorithm reserving ≥20% feed content from outside user's IES |
| **LGPD** | Lei Geral de Proteção de Dados (Brazilian data protection law) |

---

## 2. Functional Requirements

### 2.1 Authentication & Authorization

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-01** | Institutional Email Registration | Users register exclusively via institutional email. The system validates the email domain against a whitelist of approved educational domains. | User | P0 |
| **RF-02** | OTP Verification | System sends a 6-digit OTP to the institutional email. OTP expires after 10 minutes. Maximum 5 attempts before 15-minute cooldown. | User | P0 |
| **RF-03** | Password Setup | After OTP verification, user sets a password (min 8 chars, 1 uppercase, 1 number, 1 special char) and completes onboarding. | User | P0 |
| **RF-04** | JWT Authentication | Login returns a short-lived access token (15 min) and long-lived refresh token (7 days). Refresh tokens are rotated on use. | User | P0 |
| **RF-05** | Logout & Token Revocation | User can log out, which blacklists the current refresh token. | User | P0 |
| **RF-06** | Password Reset | "Forgot password" flow via OTP to the institutional email. | User | P1 |

### 2.2 Profile Management

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-07** | Profile Creation | During onboarding, user provides: full name, course, semester/period, skills (from taxonomy), interests, and optional links (GitHub, Lattes, LinkedIn). | User | P0 |
| **RF-08** | Profile Editing | User can update any profile field at any time. Changes are audited. | User | P0 |
| **RF-09** | Privacy Level | User sets profile visibility: `public` (visible to all), `local_only` (visible to same IES), or `private` (visible only to connections). Default: `local_only`. | User | P0 |
| **RF-10** | Profile Viewing | Users can view other profiles respecting the target's privacy level and the viewer's institution. | User | P0 |
| **RF-11** | Skill Taxonomy | Skills are selected from a curated, searchable taxonomy (not free-text). Admins can add new skills. Categories: Programming, Design, Sciences, Languages, etc. | User, Admin | P1 |

### 2.3 Discovery & Connections

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-12** | Cross-University Search | Search users by: skill, institution, course, semester. Supports full-text search on names. Results respect privacy settings. | User | P0 |
| **RF-13** | Connection Requests | User A sends a connection request to User B. User B can accept, reject, or ignore. Accepted connections enable private messaging regardless of privacy level. | User | P0 |
| **RF-14** | Connection Management | Users can view their connections, pending requests (sent/received), and remove existing connections. | User | P0 |
| **RF-15** | Block User | Users can block other users. Blocked users cannot send messages, connection requests, or view the blocker's profile. | User | P1 |

### 2.4 Feed & Content

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-16** | Post Creation | Users can create text posts with optional image/file attachments (max 10MB, types: JPG, PNG, PDF). | User | P0 |
| **RF-17** | Local Feed | Displays posts from users at the same IES, sorted by recency. Cursor-based pagination (20 posts per page). | User | P0 |
| **RF-18** | Global Feed | Displays posts from all IES. Must apply Force Exploration: ≥20% of visible posts from non-user IES. Cursor-based pagination. | User | P0 |
| **RF-19** | Feed Toggle | UI toggle switches between Local and Global feeds. State persists per session. Load time < 2 seconds. | User | P0 |
| **RF-20** | Post Deletion | Users can delete their own posts. Soft delete (marked as deleted, retained for audit for 90 days). | User | P0 |
| **RF-21** | Post Reactions | Users can react to posts (like, insightful, support). No dislike/negative reactions (Mastery Orientation). | User | P1 |
| **RF-22** | Post Comments | Users can comment on posts. Comments support text only. Threaded replies (1 level deep). | User | P1 |

### 2.5 Messaging & Collaboration

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-23** | Direct Messages (1:1) | Connected users can exchange real-time messages via WebSocket. Fallback to HTTP polling if WebSocket fails. | User | P0 |
| **RF-24** | Study Groups | Users can create study groups (max 50 members). Groups have: name, description, topic tags. Creator is admin. | User | P0 |
| **RF-25** | Group Messaging | All group members can send messages and files. Real-time via WebSocket. | User | P0 |
| **RF-26** | Message History | Full message history is persisted and paginated (cursor-based, 50 messages per page). | User | P0 |
| **RF-27** | File Sharing | Users can share files in chats (PDF, images). Files stored in object storage (S3-compatible). Max 10MB per file. | User | P1 |
| **RF-28** | Typing Indicators | Show when the other user is typing in 1:1 chats. | User | P2 |

### 2.6 Privacy & LGPD Compliance

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-29** | Consent Collection | On registration, user must accept Terms of Service and Privacy Policy. Consent is versioned with timestamps. | User | P0 |
| **RF-30** | Data Export | User can request a full export of their personal data (JSON format). System generates export within 48 hours. | User | P0 |
| **RF-31** | Account Deletion | User can request account deletion. Data is anonymized within 30 days. Cascade: posts anonymized, messages retained with anonymized sender, connections removed. | User | P0 |
| **RF-32** | Consent Withdrawal | User can revoke consent at any time, triggering account deactivation and data anonymization workflow. | User | P0 |
| **RF-33** | Audit Trail | All data access and modifications are logged with actor, action, target, and timestamp. Retained for 5 years. | System | P0 |

### 2.7 Notifications

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-34** | Push Notifications | System sends push notifications for: new messages, connection requests, post reactions. Via Firebase Cloud Messaging (FCM). | User | P1 |
| **RF-35** | In-App Notifications | Notification center within the app showing unread items. | User | P1 |
| **RF-36** | Notification Preferences | User can enable/disable notifications per category (messages, connections, feed activity). | User | P2 |

### 2.8 Administration

| ID | Requirement | Description | Actors | Priority |
|:---|:---|:---|:---|:---|
| **RF-37** | Institution Registration | Platform admin registers new IES with name, domains, and verification status. | Admin | P0 |
| **RF-38** | Domain Management | Admin adds/removes approved email domains. Domain changes do not affect existing users. | Admin | P1 |
| **RF-39** | Content Moderation | Admin can review and remove reported posts. Reported content is flagged, not auto-removed. | Admin | P1 |
| **RF-40** | Abuse Reports | Users can report posts, messages, or profiles with a reason. Reports go to a moderation queue. | User | P1 |

---

## 3. Non-Functional Requirements

| ID | Category | Requirement | Metric |
|:---|:---|:---|:---|
| **RNF-01** | Architecture | Microservices architecture with independent deployment per service. | Each service deployable independently |
| **RNF-02** | Performance | Feed load latency ≤ 2 seconds (p95). | Measured at API gateway |
| **RNF-03** | Performance | Message delivery latency ≤ 500ms (p95). | Measured end-to-end |
| **RNF-04** | Performance | Search results returned ≤ 1 second (p95). | Measured at API gateway |
| **RNF-05** | Availability | 99.5% uptime SLA for core services (Auth, Feed, Messaging). | Monthly measurement |
| **RNF-06** | Security | Encryption in transit (TLS 1.3) for all connections. Encryption at rest (AES-256) for sensitive data at the database level. | All environments |
| **RNF-07** | Security | OWASP Top 10 compliance. Input validation, parameterized queries, CSP headers. | Audit-verified |
| **RNF-08** | Scalability | System must support 100K concurrent users with horizontal scaling. | Load test verified |
| **RNF-09** | Data Retention | Soft-deleted data retained for 90 days. Audit logs retained for 5 years. | Policy-enforced |
| **RNF-10** | Compliance | Full LGPD compliance: consent management, data portability, right to erasure. | Legal review |
| **RNF-11** | Usability | The platform must intentionally omit competitive academic metrics (GPA rankings, grade comparisons). | Design review |
| **RNF-12** | Accessibility | WCAG 2.1 AA compliance for the mobile UI. | Automated + manual testing |
| **RNF-13** | Observability | Structured JSON logging, distributed tracing, health check endpoints per service. | All services |
| **RNF-14** | Internationalization | UI supports Portuguese (BR) as primary language with English as secondary. | i18n framework |

---

## 4. Business Rules

| ID | Rule | Description | Enforcement |
|:---|:---|:---|:---|
| **RN-01** | Domain Validation | Registration only succeeds if the email domain matches an approved educational domain in the `institutions` table. | Auth Service |
| **RN-02** | Privacy Masking | Users with `privacy_level = local_only` are invisible to users from different IES, unless connected. | Profile Service + API Gateway |
| **RN-03** | Force Exploration | The Global Feed must contain ≥20% posts from IES other than the viewer's. Enforced at feed generation time. | Feed Service |
| **RN-04** | No Vanity Metrics | The system must never expose: individual grades, GPA, class rankings, citation counts, or performance comparisons. | Application-wide |
| **RN-05** | OTP Rate Limit | Maximum 5 OTP attempts per email per 15-minute window. Maximum 3 OTP requests per email per hour. | Auth Service |
| **RN-06** | Connection Symmetry | Connections are bidirectional. If A is connected to B, B is connected to A. | Profile Service |
| **RN-07** | Group Size Limit | Study groups have a maximum of 50 members. | Messaging Service |
| **RN-08** | File Size Limit | Uploaded files cannot exceed 10MB. Allowed types: JPG, PNG, PDF. | Gateway + Storage Service |
| **RN-09** | Consent Versioning | When Terms or Privacy Policy change, existing users must re-consent on next login. | Auth Service |
| **RN-10** | Soft Delete Cascade | When a user deletes their account, posts are anonymized (author set to "Deleted User"), messages retain content but sender is anonymized, connections are removed. | Cross-service event |

---

## 5. Use Cases

### UC-01: Registration & Onboarding

- **Actor:** Student
- **Precondition:** User has a valid institutional email.
- **Main Flow:**
  1. User opens the app and taps "Create Account".
  2. User enters institutional email (e.g., `ana@aluno.ufmg.br`).
  3. System validates the domain against the approved list.
  4. System sends 6-digit OTP to the email.
  5. User enters OTP within 10 minutes.
  6. System verifies OTP and presents password setup screen.
  7. User creates a password meeting strength requirements.
  8. User accepts Terms of Service and Privacy Policy (versioned consent).
  9. User completes profile: name, course, semester, skills (from taxonomy).
  10. System creates the user profile and issues JWT tokens.
- **Alternate Flows:**
  - **3a.** Domain not in approved list → System shows error: "This email domain is not registered. Contact your institution."
  - **5a.** OTP expired → User taps "Resend OTP" (max 3 per hour).
  - **5b.** 5 failed OTP attempts → 15-minute cooldown enforced.
  - **7a.** Password doesn't meet requirements → Inline validation errors shown.
- **Postcondition:** User is authenticated and lands on the home feed.

### UC-02: Cross-University Discovery

- **Actor:** Authenticated User
- **Precondition:** User is logged in with a completed profile.
- **Main Flow:**
  1. User navigates to "Discover" tab.
  2. User enters search filters: skill = "Machine Learning", institution = "USP".
  3. System queries profiles matching filters, respecting privacy settings.
  4. System returns paginated results (20 per page) with: name, institution, course, top 3 skills.
  5. User taps on a profile to view details.
  6. User sends a connection request with an optional message.
- **Alternate Flows:**
  - **3a.** Target profile has `privacy_level = private` and users are not connected → Profile not shown in results.
  - **3b.** Target profile has `privacy_level = local_only` and viewer is from different IES → Profile not shown.
  - **6a.** Connection request already pending → Button shows "Request Sent" (disabled).
  - **6b.** Users are already connected → Button shows "Message" instead.
- **Postcondition:** Connection request is created with `status = pending`.

### UC-03: Feed Interaction

- **Actor:** Authenticated User
- **Main Flow:**
  1. User opens the app (defaults to Local Feed).
  2. System loads the 20 most recent posts from user's IES.
  3. User toggles to "Global Feed".
  4. System loads the merged global feed with ≥20% Force Exploration posts.
  5. User creates a new post: enters text, optionally attaches an image.
  6. System saves the post with `scope = global` (user can choose local-only).
  7. Post appears in relevant feeds in real-time for connected users.
- **Edge Cases:**
  - User's IES has < 5 posts → Local Feed backfills with Global posts (labeled "From other universities").
  - Force Exploration cannot reach 20% (few other-IES posts exist) → Show available content with a "More universities coming soon" message.

### UC-04: Messaging Flow

- **Actor:** Two Connected Users
- **Precondition:** Users A and B have an accepted connection.
- **Main Flow:**
  1. User A opens User B's profile and taps "Message".
  2. System creates (or opens existing) 1:1 chat.
  3. User A types a message → delivered via WebSocket in real-time.
  4. User B receives push notification (if app is backgrounded).
  5. User B opens the chat and reads the message.
  6. User A sees "read" indicator.
- **Alternate Flows:**
  - **3a.** WebSocket connection fails → System falls back to HTTP polling (every 3 seconds).
  - **4a.** User B has notifications disabled for messages → No push notification sent.

### UC-05: Account Deletion (LGPD)

- **Actor:** User
- **Main Flow:**
  1. User navigates to Settings → Privacy → "Delete My Account".
  2. System shows confirmation dialog explaining what will happen.
  3. User confirms by entering their password.
  4. System emits `UserDeletionRequested` event.
  5. Within 30 days: posts anonymized, messages anonymized, connections removed, profile data erased.
  6. User receives confirmation email.
- **Postcondition:** User data is fully anonymized. Account is not recoverable.

---

## 6. Acceptance Criteria (BDD/Gherkin)

### Feature: Feed Toggle

```gherkin
Scenario: Switch from Global to Local Feed
  Given the user is authenticated and belongs to "UFMG"
  And is viewing the "Global Feed"
  When the user toggles to "Local Feed"
  Then the system displays only posts from "UFMG" users
  And the load time is less than 2 seconds

Scenario: Force Exploration in Global Feed
  Given the user belongs to "USP"
  When the user views the "Global Feed"
  Then at least 20% of displayed posts are from institutions other than "USP"

Scenario: Local Feed with insufficient content
  Given the user belongs to an IES with fewer than 5 posts
  When the user views the "Local Feed"
  Then the system backfills with global posts
  And labels them "From other universities"
```

### Feature: OTP Security

```gherkin
Scenario: OTP brute force protection
  Given a user has entered 5 incorrect OTP codes
  When the user attempts a 6th OTP entry
  Then the system blocks further attempts for 15 minutes
  And displays "Too many attempts. Try again in 15 minutes."

Scenario: OTP expiration
  Given a user received an OTP at 10:00
  When the user enters the OTP at 10:11
  Then the system rejects the OTP with "Code expired. Request a new one."
```

### Feature: Privacy Masking

```gherkin
Scenario: Cross-institution visibility for local-only profiles
  Given User A belongs to "USP" with privacy_level = "local_only"
  And User B belongs to "UNICAMP" and is not connected to User A
  When User B searches for users with User A's skills
  Then User A does not appear in the search results

Scenario: Connected users bypass privacy masking
  Given User A has privacy_level = "local_only"
  And User B from a different IES is connected to User A
  When User B views User A's profile
  Then the full profile is visible
```

### Feature: Account Deletion

```gherkin
Scenario: User requests account deletion
  Given the user is authenticated
  When the user confirms account deletion with their password
  Then the system schedules data anonymization within 30 days
  And the user receives a confirmation email
  And the user is logged out immediately
```
