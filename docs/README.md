# InteraEdu — Documentação Central

Bem-vindo(a) à documentação técnica do **InteraEdu**.

Toda a documentação foi padronizada em Português do Brasil e organizada em três pilares: Arquitetura, Guias de Desenvolvimento e MVP. Use este índice como ponto de entrada antes de qualquer implementação.

---

## 🏛️ Arquitetura e Engenharia

Documentos de nível de sistema: decisões técnicas, contratos de API, modelagem de dados e estratégias de infraestrutura.

| Documento | Conteúdo |
|---|---|
| [Visão do Produto](./arquitetura/visao-produto.md) | Propósito do produto, personas, diferenciais competitivos e modelo de negócio |
| [Requisitos de Software](./arquitetura/requisitos.md) | SRS: requisitos funcionais e não-funcionais |
| [Arquitetura do Sistema](./arquitetura/sistema.md) | Diagrama de alto nível, padrões de comunicação entre serviços, stack tecnológica |
| [Design de Microsserviços](./arquitetura/microsservicos.md) | Responsabilidades de cada serviço: Auth, Profile, Feed, Messaging e Gateway |
| [Modelagem de Dados](./arquitetura/dados.md) | Schemas do PostgreSQL por serviço, entidades TypeORM, estratégia de cache Redis |
| [Design de API](./arquitetura/api.md) | Contratos REST completos: endpoints, payloads, códigos de erro e paginação |
| [Arquitetura de Segurança](./arquitetura/seguranca.md) | JWT, rotação de refresh token, OTP, rate limiting, privacidade de perfil |
| [Infraestrutura e DevOps](./arquitetura/devops.md) | Pipeline CI/CD, Docker, ambientes, observabilidade e gerenciamento de segredos |
| [Estratégia de Escalabilidade](./arquitetura/escalabilidade.md) | Roadmap de escala, cache do feed, filas BullMQ, Elasticsearch e Kubernetes |

---

## 📜 Guias de Desenvolvimento

Leitura obrigatória antes de abrir o IDE.

| Documento | Conteúdo |
|---|---|
| [Padrões de Desenvolvimento](./guias/padroes-desenvolvimento.md) | **LEITURA OBRIGATÓRIA.** Convenções de nomenclatura, estrutura de pastas, regras de negócio, o que fazer e o que evitar |
| [Catálogo de Tarefas](./guias/tarefas-ia.md) | Tarefas granulares com contexto completo para implementação das funcionalidades pendentes |

---

## 🚀 MVP — Status de Implementação

| Documento | Conteúdo |
|---|---|
| [Status de Implementação](./mvp/status-implementacao.md) | Tabela de funcionalidades ✅/⚠️/❌, o que falta construir e o roadmap de sprints |

---

### Links Úteis
- [README Raiz](../README.md) — Setup local do projeto (Docker + Flutter)
- [Walkthrough da Refatoração](./walkthrough.md) — Histórico das alterações realizadas na documentação
