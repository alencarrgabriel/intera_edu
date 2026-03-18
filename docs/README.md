# InteraEdu — Documentação Central (Índice Mestre)

Bem-vindo(a) ao repositório de documentação do **InteraEdu**.

A documentação do InteraEdu foi reescrita e padronizada (Março 2026) para ser uma Fonte Única de Verdade (Single Source of Truth) para todo o time técnico, em Português do Brasil de maneira coesa e acessível.

Abaixo você encontra o mapa com links diretos para cada arquivo essencial da engenharia do produto, dividida em três pilares: Arquitetura, Guias de Desenvolvimento e MVP.

---

## 🏛️ Pilar 1: Arquitetura e Engenharia

Todos os documentos de nível de Sistema, Carga, Decisões e Seguranças.

*   [Visão do Produto (`visao-produto.md`)](./arquitetura/visao-produto.md) — O porquê o aplicativo existe, quem ele atende e seus diferenciais de mercado.
*   [Requisitos de Software (`requisitos.md`)](./arquitetura/requisitos.md) — O SRS prático (Functional e Non-Functional Requirements).
*   [Desenho do Sistema (`sistema.md`)](./arquitetura/sistema.md) — Diagrama e explicação do Fluxo Lógico Macro entre Mobile Flutter e Microsserviços NestJS.
*   [Microsserviços (`microsservicos.md`)](./arquitetura/microsservicos.md) — As divisões core: `Auth`, `Profile`, `Feed`, `Messaging` e o `Gateway`.
*   [Modelagem de Dados (`dados.md`)](./arquitetura/dados.md) — TypeORM, Schemas Isolados do Postgres e Cache Redis.
*   [Design das APIs REST (`api.md`)](./arquitetura/api.md) — Contratos Padrão, Rate Limits e Respostas de Erro de Endpoint.
*   [Proteção e Segurança (`seguranca.md`)](./arquitetura/seguranca.md) — Rotação de Tokens (Refresh/Access), Criptografia, Roles Ocultas e Privacidade de Perfis Locais e Globais.
*   [Infraestrutura e DevOps (`devops.md`)](./arquitetura/devops.md) — CI/CD, Nuvem AWS (MinIO provisório local), Compose e Estrutura de Integrações/PullRequests.
*   [Estratégia de Escalabilidade (`escalabilidade.md`)](./arquitetura/escalabilidade.md) — Horizonte de eventos caso a rede se expanda (Sharding de Dados, Múltiplos Pods Gateways, etc).

---

## 📜 Pilar 2: Guias e Padrões de Desenvolvimento

Antes de abrir o IDE e codar um microsserviço ou tela nova, leia estes guias. Eles previnem catástrofes de arquitetura.

*   [Padrões de Desenvolvimento e Contexto Persistente (`padroes-desenvolvimento.md`)](./guias/padroes-desenvolvimento.md) — **LEITURA OBRIGATÓRIA**. Gramática de nomenclaturas, onde colocar cada tipo de arquivo de arquitetura no Flutter Clean Arch ou NestJS Typescript e O Que Nunca Fazer.
*   [Catálogo de Tarefas Operacionais (`tarefas-ia.md`)](./guias/tarefas-ia.md) — A fila de tarefas técnicas prontas para IAs (ou desenvolvedores Juniors), contendo todas as descrições limpas do que falta produzir fase a fase no projeto.

---

## 🚀 Pilar 3: MVP — Fase e Status

Onde nós estamos como produto de mercado e de código na linha do tempo ágil.

*   [Status de Implementação (`status-implementacao.md`)](./mvp/status-implementacao.md) — A listagem matriz do que de código base já foi erguido (Feito ✅) e o que de fato está faltando construir (Inexistente ❌) nas telas de Mobile e Backend.

---

### Links Relacionados
*   [README da Raiz](../README.md) — Rodando o container inicial de Dev e Setup Básico de NPM/Flutter.
*   [Changelog da Refatoração Docs (`walkthrough.md`)](./walkthrough.md) — Histórico do que mudou ativamente desta última refatoração nos arquivos markdown de docs/.
