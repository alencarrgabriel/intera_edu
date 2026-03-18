# InteraEdu — Especificação de Requisitos de Software (SRS)

**Versão:** 2.0
**Data:** Março 2026
**Status:** Arquitetura de Produção

---

## 1. Introdução

### 1.1 Objetivo
Este documento especifica os requisitos funcionais e não-funcionais do InteraEdu, uma plataforma de networking acadêmico que permite colaboração interuniversitária. Ele serve como fonte única da verdade (Single Source of Truth) para desenvolvimento, testes e validação do produto.

### 1.2 Escopo
O InteraEdu é uma plataforma **independente, nativa para nuvem (cloud-native) e multi-inquilino (multi-tenant)**. Não se integra com ERPs universitários. A autenticação é baseada em validação de domínio de e-mail institucional. O MVP é direcionado a universidades brasileiras operando sob regulamentação da LGPD.

### 1.3 Definições

| Termo | Definição |
|:---|:---|
| **IES** | Instituição de Ensino Superior |
| **Inquilino (Tenant)** | Uma IES cadastrada na plataforma |
| **OTP** | Senha de uso único (One-Time Password) para verificação de e-mail |
| **Mascaramento de Privacidade** | Lógica que controla a visibilidade de perfis entre instituições |
| **Exploração Forçada** | Algoritmo que reserva ≥20% do conteúdo do feed de fora da IES do usuário |
| **LGPD** | Lei Geral de Proteção de Dados |

---

## 2. Requisitos Funcionais

### 2.1 Autenticação e Autorização

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-01** | Registro via E-mail Institucional | Usuários se registram exclusivamente via e-mail institucional. O sistema valida o domínio contra uma lista de aprovação de domínios educacionais. | Usuário | P0 |
| **RF-02** | Verificação OTP | Sistema envia um código OTP de 6 dígitos. OTP expira após 10 min. Máximo de 5 tentativas antes de bloqueio temporário (cooldown) de 15 min. | Usuário | P0 |
| **RF-03** | Configuração de Senha | Após verificação, usuário define senha (mín. 8 caracteres, 1 maiúscula, 1 número, 1 especial) e completa o onboarding. | Usuário | P0 |
| **RF-04** | Autenticação JWT | Login retorna token de acesso (curto, 15 min) e de atualização (longo, 7 dias). Tokens de atualização são rotacionados a cada uso. | Usuário | P0 |
| **RF-05** | Encerramento de Sessão | Logout rápido, invalidando o token de atualização atual. | Usuário | P0 |
| **RF-06** | Recuperação de Senha | Fluxo "Esqueci minha senha" via OTP para o e-mail institucional. | Usuário | P1 |

### 2.2 Gerenciamento de Perfil

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-07** | Criação de Perfil | Após OTP, usuário fornece: nome, curso, semestre, habilidades (da taxonomia), interesses e links opcionais (GitHub, Lattes). | Usuário | P0 |
| **RF-08** | Edição de Perfil | Atualização a qualquer momento. Alterações são auditadas. | Usuário | P0 |
| **RF-09** | Nível de Privacidade | Máscara de visibilidade: `publico`, `apenas_local` (mesma IES), ou `privado` (apenas conexões). Padrão: `apenas_local`. | Usuário | P0 |
| **RF-10** | Visualização de Perfil | Visualização respeitando o nível de privacidade e instituição do visitante. | Usuário | P0 |
| **RF-11** | Taxonomia de Habilidades | Selecionadas de lista curada (não texto livre). Padrão: Programação, Design, etc. Admins podem estender. | Usuário, Admin | P1 |

### 2.3 Descoberta e Conexões

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-12** | Busca Interuniversitária | Busca por habilidade, IES, curso, semestre. Suporta busca por texto completo (nomes). Respeita privacidade. | Usuário | P0 |
| **RF-13** | Solicitações de Conexão | Envio, aceite, rejeição e ignorar. Conexões aceitas abrem chat independente de privacidade. | Usuário | P0 |
| **RF-14** | Gerenciamento de Conexões | Ver lista de conexões e pendentes. Remoção de parceiros antigos. | Usuário | P0 |
| **RF-15** | Bloquear Usuário | Usuários bloqueados não podem mandar mensagens ou ver o perfil do bloqueador. | Usuário | P1 |

### 2.4 Feed e Conteúdo

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-16** | Criação de Publicação | Publicação de texto + arquivo opcional (img/pdf, máx. 10MB). | Usuário | P0 |
| **RF-17** | Feed Local | Publicações de usuários da mesma IES (paginação por cursor, 20 itens). | Usuário | P0 |
| **RF-18** | Feed Global | Publicações de todas as IES, com "Exploração Forçada" de ≥20%. | Usuário | P0 |
| **RF-19** | Alternância de Feed | Botão na interface alterna entre feeds. O estado é salvo na sessão. (Carregamento < 2s). | Usuário | P0 |
| **RF-20** | Excluir Publicação | Soft delete (marcado como excluído, retido para auditoria por 90 dias). | Usuário | P0 |
| **RF-21** | Reações | Curtir, perspicaz, apoio. Sem reações negativas. | Usuário | P1 |
| **RF-22** | Comentários | Suporte apenas para texto. Respostas aninhadas com 1 nível de profundidade. | Usuário | P1 |

### 2.5 Mensagens e Colaboração

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-23** | Chat Privado (1:1) | Tempo real via WebSocket. Fallback por HTTP polling (se WebSocket cair). | Usuário | P0 |
| **RF-24** | Grupos de Estudo | Grupos de até 50 membros. Nome, descrição, tags. Criador vira admin. | Usuário | P0 |
| **RF-25** | Resenha em Grupo | Mensagens e arquivos para o grupo em tempo real. | Usuário | P0 |
| **RF-26** | Histórico de Chat | Mensagens antigas persistidas e com rolagem infinita. | Usuário | P0 |
| **RF-27** | Arquivos no Chat | Limite de 10MB para PDFs e imagens via armazenamento em nuvem S3. | Usuário | P1 |
| **RF-28** | Indicador de Digitação | Mostra "X está digitando..." nos chats. | Usuário | P2 |

### 2.6 Privacidade e LGPD

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-29** | Consentimento LGPD | Termos e Políticas aceitos formalmente, guardados no banco com data e hora. | Usuário | P0 |
| **RF-30** | Exportação de Dados | Exportar dados em JSON em até 48 horas. | Usuário | P0 |
| **RF-31** | Exclusão de Conta | Anonimização dos dados em até 30 dias após a solicitação. Respaldo técnico em cascata. | Usuário | P0 |
| **RF-32** | Tirar Consentimento | Fluxo prático para revogação, ativando exclusão e anonimização em massa. | Usuário | P0 |
| **RF-33** | Trilha de Auditoria | Transações de estado mantidas por 5 anos para compliance. | Sistema | P0 |

### 2.7 Notificações

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-34** | Notificações Push | Firebase FCM (conexões novas, mensagens não lidas, alertas). | Usuário | P1 |
| **RF-35** | Central no Aplicativo | Lista de alertas não lidos interna da aplicação. | Usuário | P1 |
| **RF-36** | Configurações de Push | Silenciar notificações do feed, manter apenas de mensagens etc. | Usuário | P2 |

### 2.8 Administração

| ID | Requisito | Descrição | Atores | Prioridade |
|:---|:---|:---|:---|:---|
| **RF-37** | Cadastro de Nova IES | Gestão interna de novos polos educacionais. | Admin | P0 |
| **RF-38** | Aprovação de Domínios | Lista branca de e-mails (`@usp.br`, `@ufmg.br`). | Admin | P1 |
| **RF-39** | Moderação | Denúncias são enfileiradas e a exclusão da publicação requer verificação humana. | Admin | P1 |
| **RF-40** | Reportar Abuso | Botão "Denunciar" disponível no Feed, Perfil e Chats. | Usuário | P1 |

---

## 3. Requisitos Não-Funcionais

| ID | Categoria | Requisito | Métrica |
|:---|:---|:---|:---|
| **RNF-01** | Arquitetura | Microsserviços para permitir desploys modulares independentes. | Nível de Container |
| **RNF-02** | Perfomance | Latência do Feed < 2 segundos (P95). | Gateway |
| **RNF-03** | Perfomance | Entrega do Chat < 500 milisegundos (P95). | Fim-a-fim |
| **RNF-04** | Perfomance | Pesquisa com resultado rápido e fluído < 1s. | Gateway |
| **RNF-05** | Estabilidade | 99,5% do tempo no ar em módulos críticos (Chat, Feed, Login). | Mensal |
| **RNF-06** | Segurança | Criptografia em Trânsito (TLS 1.3) e Repouso (AES-256 no banco). | Geral |
| **RNF-07** | Segurança | Auditoria base frente a falhas comuns (OWASP Top 10), injeções ou XSS. | Código |
| **RNF-08** | Escalabilidade | 100K acessos sem impacto por causa da expansão em cluster. | Horizontal |
| **RNF-09** | Gestão de Resíduo | Dados apagados retidos para justiça/governança por 90 dias / Logs por 5 anos. | Geral |
| **RNF-10** | Jurídico | Práticas 100% aderentes à Lei Geral de Proteção de Dados do Brasil. | LGPD |
| **RNF-11** | Produto (UX) | Nenhum ranqueamento numérico competitivo na interface. | Telas |
| **RNF-12** | Acessibilidade | Padrão WCAG 2.1 AA na tela do dispositivo móvel. | Mobile |
| **RNF-13** | Monitoramento | Logs de transação estruturados em JSON, monitoráveis via Grafana. | DevOps |
| **RNF-14** | Idiomas | Primeira opção sempre **Português do Brasil (pt-BR)**. | UI |

---

## 4. Regras de Negócio Fundamentais

| ID | Regra | Descrição | Onde Ocorre |
|:---|:---|:---|:---|
| **RN-01** | Filtro Acadêmico | Cadastro negado imediatamente se o domínio não estiver na Whitelist. | Microsserviço de Auth |
| **RN-02** | Privilégio de Contexto | Perfis "Apenas Local" são apagados completamente das rotas e buscas de IES externas. | API Gateway + Perfil |
| **RN-03** | Pote Interinstitucional | O Feed Global tem meta constante de injetar ≥20% de IES rivais/afiliadas na tela. | Microsserviço de Feed |
| **RN-04** | Foco Humanista | A interface do portal da aplicação esconde completamente notas da faculdade ou ranking de estudantes. | Mobile |
| **RN-05** | Limite OTP | Trata spans: só envia e-mail 3x na hora, ou permite tentar 5 senhas incorretas na UI (depois bloqueio de 15 min). | Auth |
| **RN-06** | Aceite Mútuo | Ninguém aparece conectado do nada. Ação tem de partir de Vini, e Enzo precisa afirmar "Aceitar". | Profile |
| **RN-07** | Grupo Razoável | 50 pessoas máximo num grupo do projeto (impede salas mortas). | Messaging / Chat |
| **RN-08** | Peso do Arquivo | Bloquear requisições acima de 10 megabytes estritamente. | MinIO / Proxy |
| **RN-09** | Re-Consentimento | Caso o termo de uso mude, no primeiro login útil a interface do Mobile trava forçando ler as novidades e aceitar de novo. | Auth + UI |
| **RN-10** | Deleção Encadeada | Quando a conta é solicitada para fechar, desfaz os vínculos, limpa e falseia todas as amizades ativas por tabela. | Evento em Fila (Redis) |
