# InteraEdu — entrega acadêmica

Aplicação Flutter com serviços NestJS para autenticação institucional, perfis, feed e mensagens.

Esta entrega inclui especificação As-Built com inventário de rotas/DTOs/entidades, harness de testes Flutter/backend, cobertura, configuração Docker de demonstração, guia de execução e retrospectiva de Davi Vieira.

As correções desta preparação incluem isolamento do cache do feed por usuário, identidade de consentimento obtida do JWT, token para notificações internas, healthchecks públicos dos serviços e readiness do gateway. Cópias JavaScript compiladas junto aos fontes TypeScript e caches versionados foram removidos.

Consulte os relatórios anexados à release para os resultados do commit liberado. A aprovação dos testes não equivale a cobertura total. O ambiente entregue é de demonstração: usa sincronização TypeORM em desenvolvimento, Redis Pub/Sub best-effort e objetos MinIO com leitura pública. As limitações funcionais e operacionais estão descritas no SDD.

Responsável: Davi Vieira. Ferramentas de IA utilizadas no projeto: Claude e ChatGPT.
