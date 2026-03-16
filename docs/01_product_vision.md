# InteraEdu — Product Vision Document

**Version:** 2.0
**Date:** March 2026
**Status:** Production Architecture

---

## 1. Vision Statement

InteraEdu is an **academic networking platform** designed to break institutional silos by enabling cross-university collaboration between students and researchers based on skills, interests, and academic goals — not institutional affiliation.

**Core thesis**: Universities are walled gardens. A Chemistry student at USP with machine learning skills has no way to find a Computer Science student at UNICAMP working on drug discovery. InteraEdu is the bridge.

**Design philosophy**: **Mastery Orientation** — the platform intentionally omits competitive metrics (grade rankings, GPA comparisons, citation counts) and promotes collaboration, skill-sharing, and knowledge discovery.

---

## 2. Target Personas

| Persona | Description | Key Needs |
|:---|:---|:---|
| **Ana — Undergraduate Student** | 3rd semester CS at UFMG. Strong in Python, wants to join research projects at other universities. | Discover peers with complementary skills; join study groups across institutions. |
| **Carlos — Graduate Researcher** | Masters in Biotechnology at USP. Needs a data analysis partner for his thesis. | Search for collaborators by specific skills; private messaging to initiate projects. |
| **Prof. Lúcia — Research Advisor** | Professor at UFRJ. Wants to connect promising students from other universities for interdisciplinary projects. | Browse student profiles across institutions; create project-oriented study groups. |
| **IES Admin** | IT administrator at a university. Needs to register and manage institutional domains. | Domain verification, user analytics (anonymized), compliance reports. |

---

## 3. Competitive Differentiation

| Feature | LinkedIn | ResearchGate | ORCID | InteraEdu |
|:---|:---|:---|:---|:---|
| Academic-only access | ❌ | ❌ | ✅ | ✅ (domain-validated) |
| Cross-university discovery | ❌ | ⚠️ (limited) | ❌ | ✅ (core feature) |
| Skill-based matching | ✅ | ❌ | ❌ | ✅ |
| Mastery Orientation (no vanity metrics) | ❌ | ❌ | ❌ | ✅ |
| Real-time collaboration (chat + groups) | ❌ | ❌ | ❌ | ✅ |
| LGPD-native privacy controls | ❌ | ❌ | ❌ | ✅ |
| Feed with "Force Exploration" | ❌ | ❌ | ❌ | ✅ |

---

## 4. Success Metrics (KPIs)

| Metric | Target (MVP) | Target (6-month) |
|:---|:---|:---|
| Registered universities | 5 | 50 |
| Active users (MAU) | 500 | 50,000 |
| Cross-university connections made | 100 | 10,000 |
| Messages sent per week | 1,000 | 100,000 |
| Study groups created | 50 | 5,000 |
| DAU/MAU ratio | 20% | 30% |
| Feed engagement rate | 10% | 15% |
| Average session duration | 5 min | 8 min |

---

## 5. Business Model Considerations

### Phase 1 (MVP — Free)
- All features free for students and institutions.
- Focus on user acquisition and network effects.

### Phase 2 (Growth — Freemium)
- **Free tier**: Core features (profile, search, feed, basic messaging).
- **Premium tier** (per-institution license): Advanced analytics, API access, bulk invitations, priority support, white-label options.
- **Revenue streams**: Institutional SaaS licensing, sponsored academic events, premium study group features.

### Phase 3 (Scale)
- Marketplace for academic services (tutoring, project collaboration).
- Research funding discovery integration.
- Career opportunities from partner companies (opt-in, privacy-respecting).

---

## 6. Core Design Principles

1. **Privacy by Design** — LGPD compliance is not an afterthought; it shapes every data flow.
2. **No Vanity Metrics** — Rankings, grades, and competitive comparisons are architecturally forbidden.
3. **Exploration over Echo Chambers** — The "Force Exploration" algorithm ensures ≥20% of feed content comes from outside the user's institution.
4. **Standalone Operation** — No dependency on university ERPs, SIS, or LMS systems.
5. **Mobile-First** — The primary interface is a native mobile app (Flutter); web is a secondary channel.

---

## 7. Scope Boundaries

### In Scope (MVP)
- Institutional email validation (OTP/Magic Link)
- Academic profile management
- Cross-university user search
- Dual-mode feed (Local / Global)
- 1:1 messaging and study groups
- Privacy controls (LGPD)

### Out of Scope (MVP)
- ERP / SIS integration
- Video conferencing
- Academic calendar sync
- Grade sharing or academic performance tracking
- Payment processing
- Content moderation AI (manual moderation only initially)
- Web application (mobile-only MVP)
