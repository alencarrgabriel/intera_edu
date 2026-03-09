# Arquitetura Técnica e Stack de Tecnologia - InteraEdu

## 1. Visão Geral da Arquitetura
O InteraEdu utiliza uma arquitetura de **Microsserviços Standalone** baseada em eventos, operando em um modelo **Multi-tenant** com isolamento lógico.

### Componentes Principais:
1.  **API Gateway**: Ponto de entrada único para o Frontend (Mobile/Web). Responsável por roteamento, autenticação inicial e rate limiting.
2.  **Serviço de Identidade (Auth Service)**:
    *   Validação de domínio de e-mail institucional.
    *   Geração de OTP/Magic Links.
    *   Gestão de JWT e permissões.
3.  **Serviço de Perfil (Profile Service)**:
    *   Gestão de metadados de usuários (Habilidades, IES, Curso).
    *   Lógica de visibilidade (Privacy Masking).
4.  **Serviço de Feed e Social (Feed Service)**:
    *   Agregação de posts locais e globais.
    *   Implementação da regra "Force Exploration" (20%).
5.  **Serviço de Mensageria (Messaging Service)**:
    *   Comunicação em tempo real (WebSockets).
    *   Gestão de grupos e histórico.

---

## 2. Stack de Tecnologia Sugerida (Premium & Scalable)

### Backend (Microserviços)
*   **Linguagem**: **Node.js (TypeScript)** ou **Go (Golang)**.
    *   *Motivo*: Alta performance para I/O (mensagens/feed) e facilidade de deploy em containers.
*   **Framework**: NestJS (se Node) ou Gin (se Go).
*   **Comunicação**: gRPC para serviços internos e REST/GraphQL para o Frontend.

### Frontend
*   **Mobile**: **Flutter** ou **React Native**.
    *   *Sugestão Flutter*: UX mais fluida e componentes "premium" nativos.
*   **Web**: **Next.js** (React) com Tailwind CSS para design responsivo e rápido.

### Persistência de Dados
*   **Banco Principal**: **PostgreSQL**.
    *   *Estratégia Multi-tenant*: Esquema compartilhado com `tenant_id` (IES_ID) em todas as tabelas críticas para isolamento lógico.
*   **Cache & Real-time**: **Redis**.
    *   *Uso*: Cache de feed, sessões e pub/sub de mensagens.
*   **Arquivos**: AWS S3 ou Google Cloud Storage (PDFs/Imagens de perfil).

### Infraestrutura & DevOps
*   **Containerização**: Docker + Kubernetes (EKS/GKE).
*   **CI/CD**: GitHub Actions.
*   **Monitoramento**: Prometheus + Grafana.

---

## 3. Estratégia de Multi-tenancy
Para garantir a separação entre instituições sem a complexidade de múltiplos bancos:
*   Cada Instituição (IES) é um **Tenant**.
*   Toda query de dados (Feed, Usuários) deve obrigatoriamente incluir o filtro `institution_id`.
*   A autenticação garante que o usuário só acesse o "Feed Local" de sua respectiva IES.
