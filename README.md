# InteraEdu

> **Rede social acadêmica** exclusiva para universitários, com identidade verificada por e-mail institucional.

---

## 📑 Documentação do Projeto

Este projeto possui documentação técnica completa, organizada e 100% em Português do Brasil na pasta `/docs`.

**Antes de modificar qualquer código (Flutter ou NestJS), leia a documentação.**

👉 **[Acesse o Índice Central de Documentação](./docs/README.md)** 👈

Atalhos rápidos:
- 📐 [Padrões e Convenções de Desenvolvimento](./docs/guias/padroes-desenvolvimento.md)
- 🏗️ [Arquitetura do Sistema](./docs/arquitetura/sistema.md)
- 📊 [Status de Implementação do MVP](./docs/mvp/status-implementacao.md)

---

## ⚡ Como Rodar o Projeto Localmente

### 1. Backend (Microsserviços em Docker)

```bash
cd backend
cp .env.example .env  # preencha as variáveis de ambiente
docker-compose up --build
```

> O API Gateway ficará disponível em: `http://localhost:3000/api/v1`

### 2. App Mobile (Flutter)

```bash
# Na raiz do projeto:
flutter pub get

# Configure a URL da API em lib/core/config/app_config.dart:
# - Emulador Android: apiBaseUrl = 'http://10.0.2.2:3000/api/v1'
# - Chrome (web dev): apiBaseUrl = 'http://localhost:3000/api/v1'

flutter run
```

---

## ⚙️ Tecnologias

| Camada | Stack |
|---|---|
| **Backend** | Node.js 20 + NestJS 10 + TypeScript, TypeORM, PostgreSQL 16, Redis 7, MinIO |
| **Mobile** | Flutter 3.11+ (Dart), Clean Architecture |
| **Infraestrutura** | Docker + Docker Compose |

---

*Para diagramas, decisões arquiteturais e guias de desenvolvimento, consulte [`/docs/README.md`](./docs/README.md).*
