# Guia de Inicialização e Roadmap - InteraEdu

Este guia orienta o início do desenvolvimento e define as fases até o lançamento do MVP.

## 1. Setup Inicial do Projeto (Workflow Sugerido)

### Backend (Node/TypeScript)
1.  `mkdir backend && cd backend`
2.  `npm init -y && npm install express typescript nestjs` (ou framework de escolha).
3.  Configurar **Docker Compose** com PostgreSQL e Redis.
4.  Implementar o `AuthService` como prioridade (Validação de Domínio).

### Frontend (Flutter)
1.  `flutter create mobile_app`
2.  Estruturar por pastas: `layers/domain`, `layers/data`, `layers/ui`.
3.  Implementar telas de Login/OTP e Perfil.

---

## 2. Roadmap de Desenvolvimento (MVP)

### Fase 1: Fundação & Auth (Semanas 1-2)
*   Setup da Infra (AWS/GCP).
*   Serviço de Autenticação com Validação de E-mail Institucional.
*   Interface Simple UI de Onboarding.

### Fase 2: Perfil & Busca (Semanas 3-4)
*   Busca avançada por tags (ElasticSearch ou Postgres GIN indices).
*   Sistema de Conexões (Solicitar/Aceitar).
*   Aba "Descobrir" no App.

### Fase 3: Feed & Interação (Semanas 5-6)
*   Implementação do Feed Local e Global.
*   Lógica de Toggle e Cache de Feed.
*   Postagem de conteúdo básico.

### Fase 4: Mensageria & Real-time (Semanas 7-8)
*   WebSockets para mensagens 1:1.
*   Upload de arquivos (PDF) para S3.
*   Sistema de notificações Push (Firebase).

### Fase 5: LGPD & Refinamento (Semana 9)
*   Ajustes de Privacy Masking.
*   Auditoria de segurança de dados.
*   Beta Testing com público restrito (2 universidades).

---

## 3. Lista de Checagem Critica (Do's and Don'ts)
- **DO**: Validar domínios educacionais rigorosamente.
- **DO**: Focar na performance do feed (Paging/Infinite Scroll).
- **DON'T**: Implementar rankings ou métricas de notas.
- **DON'T**: Integrar com ERPs acadêmicos nesta fase.
