# InteraEdu — Documento de Visão do Produto

**Versão:** 2.0
**Data:** Março 2026
**Status:** Arquitetura de Produção

---

## 1. Declaração de Visão

O InteraEdu é uma **plataforma de networking acadêmico** projetada para quebrar silos institucionais, permitindo a colaboração interuniversitária entre estudantes e pesquisadores com base em habilidades, interesses e objetivos acadêmicos — não em afiliação institucional.

**Tese central**: Universidades são jardins murados. Um estudante de Química da USP com habilidades em machine learning não tem como encontrar um estudante de Ciência da Computação da UNICAMP trabalhando em descoberta de medicamentos. O InteraEdu é a ponte.

**Filosofia de design**: **Mastery Orientation** — a plataforma intencionalmente omite métricas competitivas (rankings de notas, comparações de CRA, contagem de citações) e promove colaboração, compartilhamento de habilidades e descoberta de conhecimento.

---

## 2. Personas-Alvo

| Persona | Descrição | Necessidades Principais |
|:---|:---|:---|
| **Ana — Estudante de Graduação** | 3º período de CC na UFMG. Forte em Python, quer participar de projetos de pesquisa em outras universidades. | Descobrir pares com habilidades complementares; participar de grupos de estudo entre instituições. |
| **Carlos — Pesquisador de Pós-Graduação** | Mestrado em Biotecnologia na USP. Precisa de um parceiro de análise de dados para sua dissertação. | Buscar colaboradores por habilidades específicas; mensagens privadas para iniciar projetos. |
| **Profa. Lúcia — Orientadora de Pesquisa** | Professora na UFRJ. Quer conectar estudantes promissores de outras universidades para projetos interdisciplinares. | Navegar perfis de estudantes entre instituições; criar grupos de estudo orientados a projetos. |
| **Admin IES** | Administrador de TI em uma universidade. Precisa registrar e gerenciar domínios institucionais. | Verificação de domínio, análise de dados de usuários (anonimizados), relatórios de conformidade. |

---

## 3. Diferenciação Competitiva

| Funcionalidade | LinkedIn | ResearchGate | ORCID | InteraEdu |
|:---|:---|:---|:---|:---|
| Acesso exclusivo acadêmico | ❌ | ❌ | ✅ | ✅ (validado por domínio) |
| Descoberta interuniversitária | ❌ | ⚠️ (limitada) | ❌ | ✅ (funcionalidade central) |
| Combinação por habilidades | ✅ | ❌ | ❌ | ✅ |
| Mastery Orientation (sem métricas de vaidade) | ❌ | ❌ | ❌ | ✅ |
| Colaboração em tempo real (chat + grupos) | ❌ | ❌ | ❌ | ✅ |
| Controles de privacidade nativos LGPD | ❌ | ❌ | ❌ | ✅ |
| Feed com "Exploração Forçada" | ❌ | ❌ | ❌ | ✅ |

---

## 4. Métricas de Sucesso (KPIs)

| Métrica | Meta (MVP) | Meta (6 meses) |
|:---|:---|:---|
| Universidades registradas | 5 | 50 |
| Usuários ativos mensais (MAU) | 500 | 50.000 |
| Conexões interuniversitárias realizadas | 100 | 10.000 |
| Mensagens enviadas por semana | 1.000 | 100.000 |
| Grupos de estudo criados | 50 | 5.000 |
| Razão DAU/MAU | 20% | 30% |
| Taxa de engajamento do feed | 10% | 15% |
| Duração média da sessão | 5 min | 8 min |

---

## 5. Considerações sobre Modelo de Negócio

### Fase 1 (MVP — Gratuito)
- Todas as funcionalidades gratuitas para estudantes e instituições.
- Foco em aquisição de usuários e efeitos de rede.

### Fase 2 (Crescimento — Freemium)
- **Camada gratuita**: Funcionalidades principais (perfil, busca, feed, mensagens básicas).
- **Camada premium** (licença por instituição): Análises avançadas, acesso à API, convites em massa, suporte prioritário, opções de customização (white-label).
- **Fontes de receita**: Licenciamento SaaS institucional, eventos acadêmicos patrocinados, funcionalidades premium de grupos de estudo.

### Fase 3 (Escala)
- Mercado para serviços acadêmicos (tutoria, colaboração em projetos).
- Integração com descoberta de financiamento de pesquisa.
- Oportunidades de carreira de empresas parceiras (opt-in, respeitando privacidade).

---

## 6. Princípios de Design

1. **Privacy by Design** — A conformidade com a LGPD não é um adendo; ela molda cada fluxo de dados.
2. **Sem Métricas de Vaidade** — Rankings, notas e comparações competitivas são arquiteturalmente proibidos.
3. **Exploração acima de Câmaras de Eco** — O algoritmo "Exploração Forçada" garante que ≥20% do conteúdo do feed venha de fora da instituição do usuário.
4. **Operação Autônoma** — Sem dependência de sistemas acadêmicos corporativos (ERPs, SIS ou LMS universitários).
5. **Mobile-First** — A interface principal é um aplicativo móvel nativo (Flutter); ambiente web é um canal secundário.

---

## 7. Limites de Escopo

### Dentro do Escopo (MVP)
- Validação de e-mail institucional (OTP)
- Gerenciamento de perfil acadêmico
- Busca interuniversitária de usuários
- Feed de modo duplo (Local / Global)
- Mensagens individuais (1:1) e grupos de estudo
- Controles de privacidade (LGPD)

### Fora do Escopo (MVP)
- Integração com sistemas acadêmicos corporativos (ERP / SIS)
- Videoconferência
- Sincronização de calendário acadêmico
- Compartilhamento de notas ou acompanhamento de desempenho acadêmico
- Processamento de pagamentos
- Moderação de conteúdo por Inteligência Artificial (apenas moderação manual inicialmente)
- Aplicação web (MVP apenas mobile)
