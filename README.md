# InteraEdu - Plataforma de Networking Acadêmico

Bem-vindo ao repositório do **InteraEdu**, uma plataforma inovadora de networking acadêmico interuniversitário. Nossa missão é quebrar "silos" institucionais, permitindo que estudantes e pesquisadores colaborem com base em habilidades e interesses, promovendo uma cultura de **Mastery Orientation**.

## 📖 Documentação do Projeto

Toda a documentação técnica, de produto e de arquitetura do projeto foi estruturada na pasta `docs/`. Recomendamos a leitura na seguinte ordem para um entendimento completo do sistema:

- 🎯 **[Requisitos de Software (SRS)](docs/SRS.md)**: Visão de produto, requisitos funcionais/não-funcionais, regras de negócio e casos de uso principais.
- 🏗️ **[Arquitetura e Stack (Architecture)](docs/Architecture.md)**: Decisões arquiteturais (Microsserviços Standalone), estratégia multi-tenant e stack tecnológica sugerida.
- 💾 **[Modelo de Dados (DataModel)](docs/DataModel.md)**: Estrutura lógica preliminar do banco de dados relacional (PostgreSQL).
- 🔌 **[Especificação da API (API_Spec)](docs/API_Spec.md)**: Contratos e principais endpoints RESTful para integração com o Frontend.
- 🗺️ **[Roadmap e Setup (Roadmap)](docs/Roadmap.md)**: Fases de desenvolvimento até o MVP, guia de inicialização e diretrizes críticas (Do's and Don'ts).

## 🚀 Sobre o Projeto

O InteraEdu opera de forma autônoma em relação aos ERPs acadêmicos tradicionais, adotando um modelo focado na privacidade discente e na colaboração inter-institucional.

### Principais Funcionalidades (MVP)
- **Autenticação Institucional Governança**: Acesso exclusivo via e-mails educacionais validados.
- **Busca Interuniversitária Avançada**: Encontre pares com habilidades complementares em qualquer IES do país.
- **Feed Dinâmico Híbrido**: Alterne rapidamente entre um Feed Local (sua universidade) e um Feed Global (toda a base).
- **Colaboração em Tempo Real**: Chat 1:1 e grupos de estudo embarcados.
- **Privacy by Design**: Foco estrito nas diretrizes da LGPD com controle absoluto de visibilidade por parte do aluno.

## 📱 Tecnologias e Frontend (Mobile)

Este repositório central atua como ponto de partida (monorepo ou repo do app) que conterá o Frontend Mobile em **Flutter**.

**Stack Local (Mobile):**
- [Flutter](https://flutter.dev/) (SDK ^3.11.0)
- Dart
- Gerenciamento de pacotes via `pubspec.yaml`

## 🛠️ Como Iniciar o Desenvolvimento (Mobile)

1. Certifique-se de ter o ecossistema [Flutter](https://docs.flutter.dev/get-started/install) corretamente instalado e configurado em sua máquina.
2. Clone este repositório.
3. Baixe as dependências do projeto:
   ```bash
   flutter pub get
   ```
4. Execute o aplicativo em um emulador ou dispositivo físico:
   ```bash
   flutter run
   ```

*Nota: Para inicialização dos serviços backend listados na arquitetura (Node.js/Go, bancos de dados em container, etc.), consulte o documento de **[Roadmap](docs/Roadmap.md)**.*

---
*InteraEdu - Conectando mentes, expandindo o conhecimento sem fronteiras.*
