# InteraEdu

> **Rede social acadêmica** restrita e validada em ambiente virtual que conecta universitários de forma exclusiva, funcional e segura.

---

## 📑 A Documentação Principal Desse Projeto

Diferente de muitos repositórios, este aplicativo e seu ecossistema **possuem uma documentação exaustiva, profissional e 100% em português brasileiro** localizada na nossa pasta central `/docs`.

Antes de você mexer em qualquer linha de código (Flutter ou Node/NestJs), é mandatório o entendimento da nossa Arquitetura Mestra e Padrões Base Apoiadores.

👉 **Vá direto para: [Índice Mestre de Engenharia, Guias e MVP](./docs/README.md).** 👈

**(Ou acesse algumas ramificações isoladas diretas caso tenha pressa):**
* 📕 [Padrões Rígidos de Desenvolvimento e Estruturas](./docs/guias/padroes-desenvolvimento.md)
* 💡 [Visão Macro e Justificativa de Arquitetura Limpa](./docs/arquitetura/sistema.md)
* 📊 [O Status de Produção e MVP — O que já está vivo?](./docs/mvp/status-implementacao.md)

---

## ⚡ Setup Dev Básico: Rodando o Projeto Completo

Abaixo os passos básicos e sujos para colocar o chassi do backend/mobile vivo localmente. *(Os detalhes e armações profundas estão na documentação da sub-pasta `/docs` e nos seus guias de uso)*.

### 1. Backend e Microsserviços (Em Containers)

```bash
cd backend
cp .env.example .env  # configure as variáveis de ambiente locais do desenvolvedor (ou use o mock falso base)
docker-compose up --build
```
> Após as máquinas subirem, o serviço primário Gateway estará atendendo requisições HTTP na fronteira em: `http://localhost:3000/api/v1`

### 2. Frontend Mobile View (Flutter / Dart)

```bash
# Na raiz do projeto / mobile:
flutter pub get

# Configure a URL da API em lib/core/config/app_config.dart
# ex: apiBaseUrl = 'http://10.0.2.2:3000/api/v1' (No uso emulador Android Local)
# ex: apiBaseUrl = 'http://localhost:3000/api/v1' (Para Chrome Web Dev Tester Local)

flutter run
```

---

## ⚙️ Tecnologias Fatais Empregadas

- **Back-end Core:** Microsserviços baseados em Node.js (20+) + Framework NestJS Frio (10+) rodando sob Linguagem TypeScript Fortemente Tipada. Banco Central TypeORM batendo num Relacional Poderoso PostgreSQL (16). E Cache de Filas Ocultas usando Redis (7). Armazém de Fotos Temporário Falso Cloud MinIO em Docker.
- **Mobile C:** Flutter Clean Architecture Brutal (Camadas cegas UI x Repositories) batendo pacotes base de request nativo e lib dart de base HTTP.

---
*Para um entendimento amplo de toda Base de Código com Diagramas, leia as pastas mapeadas em [`/docs/README.md`](./docs/README.md).*
