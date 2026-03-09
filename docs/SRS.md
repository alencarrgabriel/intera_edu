# Documento de Requisitos de Software (SRS) - InteraEdu

**Versão:** 1.0  
**Status:** MVP  
**Data:** 23 de Fevereiro de 2026  

---

## 1. Introdução e Propósito
Este documento define as especificações técnicas e funcionais para o **InteraEdu**, uma plataforma de networking acadêmico interuniversitário. O sistema opera de forma *standalone* (independente de ERPs acadêmicos) e segue um modelo *multi-tenant* em nuvem.

O propósito central é quebrar os "silos" institucionais, permitindo que estudantes e pesquisadores colaborem com base em habilidades e interesses, promovendo uma cultura de **Mastery Orientation** (foco no aprendizado e cooperação) em vez de competição por métricas de vaidade.

---

## 2. Requisitos Funcionais (RF)

| ID | Requisito | Descrição | Atores |
|:---|:---|:---|:---|
| **RF-01** | **Autenticação Institucional** | O sistema deve validar o usuário exclusivamente através do domínio de e-mail institucional (ex: `@aluno.unb.br`) via OTP (One-Time Password) ou Magic Link. | Usuário |
| **RF-02** | **Gestão de Perfil Acadêmico** | Permite a criação de perfil contendo IES, curso, período, habilidades (tags configuráveis), interesses e links (GitHub, Lattes). | Usuário |
| **RF-03** | **Busca Interuniversitária** | Mecanismo de busca avançada com filtros por habilidades, cursos e instituições de ensino. | Usuário |
| **RF-04** | **Feed Dinâmico (Toggle)** | Visualização de postagens com alternância entre "Feed Local" (posts da própria IES) e "Feed Global" (rede completa). | Usuário |
| **RF-05** | **Mensageria e Colaboração** | Chat privado (1:1) e criação de Grupos de Estudo com suporte a envio de mensagens e arquivos (PDF/Imagens). | Usuário |
| **RF-06** | **Gestão de Privacidade (LGPD)** | Interface para aceite de termos (Opt-in) e configuração de visibilidade de perfil (Privacy Masking). | Usuário |

---

## 3. Requisitos Não Funcionais (RNF)

| ID | Categoria | Descrição |
|:---|:---|:---|
| **RNF-01** | **Arquitetura** | O sistema deve ser implementado em microsserviços (SOA) sobre infraestrutura Cloud, garantindo isolamento lógico de dados (*Multi-tenant*). |
| **RNF-02** | **Performance** | Latência máxima de 2 segundos para operações críticas (carregar feed e envio de mensagens). |
| **RNF-03** | **Segurança** | Criptografia de ponta a ponta para dados sensíveis e pseudonimização de identificadores em relatórios analíticos. |
| **RNF-04** | **Usabilidade** | A interface deve omitir intencionalmente métricas competitivas (rankings de notas, comparação de performance acadêmica). |

---

## 4. Regras de Negócio (RN)

| ID | Regra | Descrição |
|:---|:---|:---|
| **RN-01** | **Validação de Domínio** | O cadastro só é efetivado se o domínio do e-mail constar na lista de domínios educacionais permitidos. |
| **RN-02** | **Máscara de Privacidade** | Dados de usuários de IES diferentes só são visíveis se o perfil estiver configurado explicitamente como "Público". |
| **RN-03** | **Force Exploration** | O feed deve reservar 20% do volume de conteúdo para sugestões de IES/Cursos diferentes do usuário para evitar bolhas sociais. |

---

## 5. Casos de Uso Principais

### UC-01: Cadastro e Onboarding
- **Ator:** Estudante
- **Fluxo:** 
  1. Insere e-mail institucional.
  2. Recebe código OTP/Link no e-mail.
  3. Valida código e define senha.
  4. Aceita Termos LGPD.
  5. Completa perfil com habilidades.

### UC-02: Busca Interuniversitária de Parceiros
- **Ator:** Usuário Autenticado
- **Fluxo:**
  1. Acessa aba "Descobrir".
  2. Filtra por Habilidade (ex: "Python") e Institution (ex: "USP").
  3. Sistema lista perfis compatíveis.
  4. Usuário envia solicitação de conexão.

### UC-03: Interação no Feed e Início de Chat
- **Ator:** Usuário Autenticado
- **Fluxo:**
  1. Alterna para "Feed Global".
  2. Identifica post de colaboração.
  3. Clica em "Mensagem".
  4. Inicia conversa direta ou entra no grupo sugerido.

---

## 6. Critérios de Aceite (BDD/Gherkin)

### Funcionalidade: Toggle de Feed Local vs Global

**Cenário: Alternância para Feed Institucional**
- **Given** que o usuário está autenticado e vinculado à "Universidade X"
- **And** está visualizando o "Feed Global"
- **When** o usuário aciona o toggle para "Feed Local"
- **Then** o sistema deve filtrar imediatamente apenas postagens de outros alunos da "Universidade X"
- **And** o tempo de carregamento deve ser inferior a 2 segundos.

**Cenário: Expansão para Feed Global**
- **Given** que o usuário está no "Feed Local"
- **When** o usuário aciona o toggle para "Feed Global"
- **Then** o sistema deve exibir postagens de todas as IES cadastradas
- **And** deve aplicar a regra de 20% de "Force Exploration".
