# InteraEdu — Design de Microsserviços

**Versão:** 2.0
**Data:** Março 2026

---

## 1. Serviço de Autenticação (Auth Service)

### 1.1 Responsabilidades
- Validação do domínio de e-mail perante a instituição aprovada.
- Produção, encaminhamento e checagem de OTP (Senhas descartáveis).
- Criptografia profunda para salvaguarda da senha de acesso (Bcrypt).
- Tráfego total via Token de Acesso rápido e Token de Renovação permanente (JWT).
- Lixeira de Tokens comprometidos / Desconexão sumária (Logout).
- Catálogo mestre de reitores e universidades permitidas (Domínios de raiz do email).

### 1.2 Módulos Principais

```text
auth-service/
├── auth/               # Controller/Service base: Entrar, Renovação rápida
├── registration/       # Dita o fluxo: Entrar e-mail → Esperar Código → Informar Senha
├── otp/                # Geração curta e expurgo (via Redis Expire)
├── domain-validation/  # Validador duro da tabela branca (apenas federais aprovadas, por ex.)
├── token/              # Rotina pesada JWT, blacklist ativa e rotação.
├── institution/        # Entidade da universidade e seu domínio (ex: @unicamp.br)
└── database/           # Raízes TypeORM e migrações.
```

### 1.3 Tabelas de Domínio (Banco Auth)

| Tabela | Missão |
|:---|:---|
| `auth.institutions` | Controle das Escolas validando sua permissão |
| `auth.users_credentials` | Nome Fantasma/ID, endereço digital, encriptação e cadeado |
| `auth.refresh_tokens` | Lista viva de quem tem sessões persistidas nos celulares do mundo (7 dias) |
| `auth.otp_codes` | Listão de chaves voláteis de 6 dígitos que expiram sumariamente. |
| `auth.consent_records` | Tabela LGPD que mapeia o Sim, o Dia e a Hora de aceite das regras |

### 1.4 Dependências Cruciais
- **Redis Cache**: Evapora o OTP e breca abusos/spam (Limites de Requisição).
- **Enviador (SMTP/AWS SES)**: Joga o OTP fisicamente pro e-mail do guri.

### 1.5 Tráfego (REST)

| Verbo | Rota | Intenção |
|:---|:---|:---|
| `POST` | `/auth/register` | Abre inscrição (Verifica Escola, chuta OTP) |
| `POST` | `/auth/verify-otp` | Checa a validade de seis dígitos na memória veloz |
| `POST` | `/auth/complete-registration` | Cadastra formalmente a senha, o "aceito termos" e emite Tokens |
| `POST` | `/auth/login` | Acesso padrão (e-mail e senha casados) |
| `POST` | `/auth/refresh` | O cel manda o Refresh e ganha um Access Zero Km (Rotação) |
| `POST` | `/auth/logout` | Obliterar a sessão permanente (Revogação) |
| `POST` | `/auth/forgot-password` | Estilinga o processo de Senha via OTP |

---

## 2. Serviço de Perfis (Profile Service)

### 2.1 Responsabilidades
- Repositório orgânico da persona acadêmica (biografia, graduação principal, URLs vinculadas).
- Base da Taxonomia estrita do que a pessoa sabe e quer ser listada (Habilidades formais).
- Círculos de amizade, aceite e recusas.
- Regra cega de privacidade: barrando olhares invasivos dependendo da opção da chave.
- Ponto focal de coleta LGPD para Baixar Dados Pessoais.

### 2.2 Módulos Principais

```text
profile-service/
├── profile/        # Respostas sobre quem é o usuário, sua máscara de proteção atual
├── skills/         # Catálogo limpo de tags ("Design UI", "Bioquímica", "Machine Learning")
├── connections/    # Motor restrito de convite e encerramento de vínculo
├── search/         # Rastreador e funil com filtro fino de buscas intelectuais
└── data-export/    # Processador de ZIP amigável entregando o acervo do usuário caso ele fuja da plataforma
```

### 2.3 Tabelas de Domínio (Banco Profile)

| Tabela | Missão |
|:---|:---|
| `profile.users` | Miolo do app. Nome, ano graduação, curso base da IES, status público/privado |
| `profile.skills` | O Catálogo de habilidades. |
| `profile.user_skills` | Ponte N:N (Enzo ↔ Skill 34) |
| `profile.connections` | Motor de fluxo: Solicitou ↔ Sim/Não ↔ Vigente |
| `profile.blocked_users` | Blacklist relacional para banimentos invisíveis do app |

### 2.4 Gatilhos de Notificação

| Grito no Redis | Carga Exposta | Alarde |
|:---|:---|:---|
| `profile.updated` | ID e Nomes afetados | A pessoa retocou sua obra, avisos às redes vitrines |
| `connection.requested` | O ID Remetente e o ID Ofertado | Chamada para interagir |
| `user.blocked` | Quem blindou quem | Trancar porta e virar as costas invisívelmente |

---

## 3. Serviço Feed (A Praça Acadêmica)

### 3.1 Responsabilidades
- Tratar e gravar texto pesado originário de aluno orgânico.
- Entregar Praça Quente e Segmentada (Local) vs Múltiplo Mix Nacional com exploração (Global).
- Gerir Cache das telas, contagens de curtidas, marcações solidárias acadêmicas.
- Aceitar os Reportes (denunciar por abusos) pra análise humana.

### 3.2 Módulos Principais

```text
feed-service/
├── posts/          # Miolo duro de gravação de letras e anexos PDF/Jpg
├── feed/           # Mixagem do Exploração Forçada ≥ 20% Invasor Saudável
├── reactions/      # Corações de Suporte e Ideia
├── comments/       # Aninhamento das conversas da galera
└── reports/        # Área do pânico caso rola algo nocivo na rede
```

### 3.3 Tabelas de Domínio (Banco Feed)

| Tabela | Missão |
|:---|:---|
| `feed.posts` | Guarda em massa as comunicações dos alunos |
| `feed.reactions` | Reagiu com 'Massa' no arquivo XYZ |
| `feed.comments` | Discussão no pé da publicação |
| `feed.reports` | Denúncias aguardando moderação formal |

### 3.4 Dependência e Consumo
- Busca os perfis no Microserviço 02 como enriquecimento do painel que só conhece 'IDs frios'.
- Bate violentamente no Redis pra cache da Timeline do dia, não martelando o BD Relacional para cada scroll.

---

## 4. Serviço de Mensageria em Tempo Real (Messaging)

### 4.1 Responsabilidades
- Manter o pulso vivo das Salas Livres Directs e Grupões de 50 Acadêmicos.
- Empurrar no meio da tela no mili-segundo as palavras ditas (Sockets Web).
- Dar conta de gravação no banco de quem viu a mensagem lá no final ('Checkzinho duplo de leitura').
- Hospedagem limpa e entrega do arquivo no fluxo da mensagem pra baixar apostilas do TCC, etc.

### 4.2 Módulos Principais
```text
messaging-service/
├── chats/          # Entra e Sai, Apaga os chats, Define Adms dos grupões
├── messages/       # Quem jogou a pedra, o registro do arquivo da url no banco e ordenação da query
├── websocket/      # Pega na mão da internet sem desligar o telefone via Socket.io no Gateway
└── files/          # Faz ponte amigón com Bucket Estático com MinIO Assinado de tempo limitado
```

### 4.3 Tabelas Principais
| Tabela | Missão |
|:---|:---|
| `messaging.chats` | Cabeça do registro, seja um DM, seja Grupão 'Estudantes Python UFRJ' |
| `messaging.chat_members` | Tabela ponte conectada dizendo quem participa do Grupo Cadeira 1 |
| `messaging.messages` | Guarda de fato o que foi proferido em Data e Hora de fuso Universal. |
| `messaging.read_receipts` | O rastreamento limpo dizendo "Li essa mensagem de ID 528399 as 3 da manhã". |

### 4.4 Disparo de Alarde Externo
O serviço envia aviso `message.sent` que se assemelha a um carteiro disparador Firebase; se a conexão WS (Via celular vivo) está desconectada, a Nuvem da Google desce em forma de Pop-Up Push.
