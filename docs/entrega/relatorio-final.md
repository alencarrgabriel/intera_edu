# Relatório técnico da entrega final

Data da consolidação: 12/10/2026. Documento elaborado por inspeção do código,
da documentação e do histórico Git local. As decisões abaixo são uma consolidação
retrospectiva sujeita à homologação do grupo, não atas de reuniões passadas.

## 1. Problema, escopo e evidências

O InteraEdu busca aproximar universitários para compartilhar conhecimento e
identificar colaboradores por interesses e habilidades, com acesso institucional.
O escopo de código compreende autenticação, perfis, conexões, feed, grupos,
materiais, histórias e mensagens. Conferir a aderência ao enunciado original da
Entrega 1 com o documento entregue pelo grupo; esse documento não foi apresentado
nesta revisão. Código presente não equivale a funcionalidade integrada homologada.

O remote local aponta para https://github.com/alencarrgabriel/intera_edu.
É necessário confirmar que esse é o repositório oficial e publicar as alterações.
O histórico local contém merges dos PRs #8, #9, #10 e #11, incluindo
`fa9925b` (feat/fase-1-e-2) e `5f1b26f` (docs/cleanup). Isso evidencia o uso de
branches/PRs; não comprova quem revisou, aprovações, critérios de aceitação ou sprints.
Os commits `1ece11f`, `c2f9fc7` e `2e15069` registram ajustes para apresentação,
redirecionamento e bugs. Não foram atribuídos autores, datas de sprint ou issues
sem evidência adicional.

## 2. Registro consolidado de decisões de arquitetura (ADRs)

### ADR-001 — Flutter com separação em camadas

**Contexto:** múltiplas telas compartilham autenticação, rede e entidades.
**Decisão observada:** separar `lib/domain`, `lib/data`, `lib/presentation` e
`lib/core`; usar notifiers/Provider no estado da interface.
**Alternativa:** chamadas HTTP e estado diretamente em cada tela.
**Justificativa:** contratos de repositório permitem substituir infraestrutura e
isolar testes de estado. **Trade-off:** mais arquivos e contratos que precisam
acompanhar mudanças, como demonstrado pelos mocks de criação de posts.
**Limite:** a organização não garante que todas as telas respeitem as camadas.

### ADR-002 — NestJS por domínio e gateway HTTP

**Contexto:** autenticação, perfis, feed e mensagens têm responsabilidades distintas.
**Decisão observada:** serviços NestJS separados, pacote `shared` e gateway REST.
**Alternativa:** monólito modular.
**Justificativa:** separar responsabilidades e reaproveitar JWT/Redis/DTOs.
**Trade-off:** mais processos, configuração, chamadas de rede e pontos de falha.
Para um MVP pequeno, um monólito seria operacionalmente mais simples; a separação
atual exige demonstrar integração e não apenas compilar serviços isolados.
**Evidência:** `backend/package.json`, serviços e `backend/gateway/src/proxy`.

### ADR-003 — PostgreSQL por schema e Redis Pub/Sub

**Contexto:** persistência relacional e criação de perfil após registro.
**Decisão observada:** schemas por serviço, Redis para OTP/cache/eventos.
**Alternativa:** banco único sem fronteiras ou broker com entrega durável.
**Justificativa:** reduzir acoplamento direto entre domínios e aproveitar TTL.
**Trade-off:** Pub/Sub é best-effort; perda de evento pode deixar dados incompletos.
**Aceitação:** não anunciar entrega garantida; homologar criação de perfil e
recuperação de falhas antes de declarar o registro integrado concluído.

### ADR-004 — Sessão com JWT e renovação limitada

**Contexto:** sessão expira e requisições podem receber 401.
**Decisão:** manter tokens em armazenamento seguro, validar assinatura/expiração
no backend e limitar a uma repetição automática no cliente. Rotas de autenticação
preservam seus próprios erros. `sub` e `exp` locais orientam restauração da interface.
**Alternativa:** renovar indefinidamente ou pedir login a cada expiração.
**Trade-off:** uma segunda rejeição é devolvida ao chamador; validar claims no
cliente não substitui autorização no servidor. Falhas transitórias de rede na
renovação ainda merecem política específica para evitar logout desnecessário.
**Evidência:** cliente HTTP, `AuthNotifier`, estratégia JWT compartilhada e testes novos.

### ADR-005 — Docker Compose e armazenamento compatível com S3

**Contexto:** reproduzir backend, banco, cache e arquivos no ambiente de avaliação.
**Decisão observada:** Compose, Node 20, PostgreSQL 16, Redis 7 e MinIO.
**Alternativa:** instalar serviços manualmente ou contratar serviços gerenciados.
**Justificativa:** descrever dependências num ambiente comum.
**Trade-off:** containers consomem recursos; imagem MinIO sem versão fixa e valores
de desenvolvimento reduzem reprodutibilidade e não configuram um deploy seguro.
**Aceitação:** registrar versões/digests usados na homologação; revisar credenciais,
portas públicas e TLS antes de exposição externa.

## 3. Loop de re-especificação e critérios verificáveis

Este registro descreve refinamentos feitos nesta revisão. Não pressupõe alteração
formal do enunciado acadêmico; o grupo deve aprovar os contratos refinados.

| ID | Contrato anterior ou lacuna | Falha/evidência | Contrato refinado | Verificação |
|---|---|---|---|---|
| RE-01 | Renovar ao receber 401 sem limite explícito | Inspeção encontrou repetição recursiva | Uma renovação e uma repetição por requisição; novo 401 encerra a tentativa | Teste de 401 persistente |
| RE-02 | Todo 401 significava sessão expirada | Login rejeitado também acionava refresh | POST de autenticação devolve o erro original sem refresh automático | Teste de login rejeitado |
| RE-03 | Token armazenado bastava para restaurar sessão | Token inválido/expirado era aceito; refresh não carregava identidade | Exigir sub/exp válidos ou renovar e carregar identidade/papéis | Testes de restauração |
| RE-04 | Desautenticar alterava apenas status | userId/roles permaneciam em memória | Desautenticar também remove identidade e permissões locais | Testes de logout |
| RE-05 | Corpo de erro era presumido objeto JSON | Cast falhava com lista/null/número | Retornar ApiException estável preservando status e mensagem possível | Testes de corpos inesperados |
| RE-06 | Mocks refletiam contrato antigo de createPost | Compilação dos testes falhava | Mocks devem aceitar parâmetros de grupo e anexo | Suíte de testes de feed e tela |

Para novos refinamentos, registrar: issue, requisito afetado, reprodução, contrato
anterior/novo, impacto no usuário, teste que falhava, PR, revisão humana e resultado.
Não reescrever requisitos apenas para acomodar um defeito sem justificativa.

## 4. Testes: resultados e lacunas

Uma execução anterior nesta conversa reportou **36 testes Flutter aprovados**, com
11 testes novos de rede/sessão. O resultado é histórico: não foi reexecutado nesta
etapa e ainda precisa de log versionado ou artefato de CI associado ao commit final.
A aprovação não comprova cobertura completa nem integração com o backend.
A análise estática global teve problemas preexistentes em vendor e telas.
A análise restrita às alterações teve uma sugestão de estilo no teste de sessão.

| Cenário | Evidência disponível | Falta para homologação |
|---|---|---|
| Modelos, feed, reações e telas de login/post | Testes em test/ e execução anterior | Log do commit final |
| Login rejeitado e 401 persistente | test/network/api_client_test.dart | Execução rastreável em CI |
| Token ausente, inválido, expirado; refresh e logout | test/notifiers/auth_notifier_test.dart | Execução rastreável em CI |
| Cadastro institucional, OTP e consentimento | Código de autenticação | Testes integrados de sucesso, OTP inválido/expirado e domínio recusado |
| Privacidade e autorização | Guards e serviços | Testes de acesso de terceiros, perfis privados e instituição diferente |
| Upload, feed e mensagens | Implementação existente | Integração real, limites de arquivo, reconexão e falhas de serviço |
| Backend | Serviços TypeScript | Build e testes automatizados dos serviços; não executados nesta revisão |

O workflow `Validar testes Flutter` foi preparado para execução manual no GitHub,
com log em artefato, sem executar ou instalar nada no dispositivo desta revisão.
Ele valida apenas a suíte Flutter. Publicá-lo não equivale a executá-lo nem a passar.

## 5. Avaliação crítica das ferramentas de IA

### Método e matriz comparativa

Não houve benchmark controlado entre quatro ferramentas. A única experiência
observável nesta revisão é o assistente desta conversa; não há evidência de que
isso constitua uma execução de **Codex CLI**. A matriz distingue observação de
critérios propostos, sem inventar resultados ou atribuir funcionalidades atuais.

| Ferramenta/contexto | Ponto forte demonstrado | Limitação demonstrada | Impacto comprovável no projeto | Situação |
|---|---|---|---|---|
| Assistente Codex desta conversa | Inspeção de contratos, correção e criação de testes/documentação | Executou testes e baixou dependências antes do alinhamento explícito; precisou restringir ações à inspeção estática | Correções de sessão/erros, mocks sincronizados e documentação de entrega | Observação real; revisão humana pendente |
| Codex CLI | Não medido | Não medida | Nenhum resultado atribuível especificamente ao CLI | Não avaliado |
| Claude Code | Não medido | Não medida | Sem evidência de uso disponível | Não avaliado |
| Cursor | Não medido | Não medida | Sem evidência de uso disponível | Não avaliado |
| Antigravity | Não medido | Não medida | Sem evidência de uso disponível | Não avaliado |

Para completar a comparação exigida pelo professor, o grupo deve aplicar a pelo
menos duas ferramentas o mesmo recorte de código, especificação e tarefa: identificar
o loop de 401, propor correção e teste sem instalar dependências. Usar checkout
isolado, dados sintéticos e o mesmo limite de tempo. Registrar versão/modelo/data,
prompt, patch, tempo, número de intervenções humanas e resultado dos mesmos testes.
Pontuar de 0 a 2: aderência à especificação, correção, casos de borda, segurança,
clareza do patch e respeito ao escopo. Não atribuir nota antes de avaliar.

A lacuna de avaliação é parte do relatório, mas **não substitui o comparativo
empírico obrigatório**. O grupo precisa preencher resultados reais antes da entrega.

### Alucinação, código inseguro e ações destrutivas

Código plausível pode usar APIs inexistentes, omitir autorização ou criar loops.
Os mocks antigos exemplificam como contratos podem divergir mesmo quando o arquivo
parece correto. Uma sugestão de IA deve ser conferida contra interfaces, chamadas,
casos de borda e testes; aprovação textual do modelo não é evidência de funcionamento.
Alterações devem passar por diff e revisão de colega, sem merge automático. Comandos
que removem arquivos, alteram banco, publicam ou instalam dependências exigem escopo
explicitamente combinado. Nesta etapa, o escopo foi limitado a código/documentação.

### Privacidade, confidencialidade e exposição de contexto

Usar apenas contexto necessário e dados sintéticos. Não enviar `.env`, segredos JWT,
tokens, senhas SMTP, dados de alunos, mensagens privadas ou logs identificáveis aos
modelos. Revisar anexos e prompts antes do envio e conferir as condições de retenção
aplicáveis à conta usada pelo grupo. Em exposição real, remover o dado do material,
revogar/rotacionar a credencial e registrar o incidente; apagar uma linha do Git não
revoga um segredo. Segredos de CI devem ficar no mecanismo de secrets do provedor.

### Propriedade intelectual e autoria

Registrar onde a IA auxiliou e quem revisou, preservar licenças de dependências e
arquivos em vendor, verificar trechos copiados e não tratar código gerado como
automaticamente original ou livre de obrigações. Não foi feita auditoria de
licenciamento nesta entrega documental. O grupo deve decidir a licença do projeto
com os titulares e conferir as regras da disciplina e termos das ferramentas.
Esses cuidados são critérios de revisão, não uma conclusão jurídica sobre titularidade.

### Homologação humana no fluxo SDD

Fluxo adotado como critério de governança: problema → especificação e aceitação →
proposta de implementação → testes e inspeção → revisão humana → homologação → merge.
A IA auxilia na proposta; o grupo responde pelo contrato, autorização, segurança e
resultado apresentado. O revisor deve explicar o diff, conferir testes e aprovar
explicitamente. As decisões e refinamentos deste documento aguardam essa homologação.

## 6. Relato sintético da experiência técnica

A inspeção mostrou que separar domínio, dados e apresentação facilita localizar
falhas, mas aumenta a necessidade de manter contratos e mocks sincronizados.
O caso de renovação de sessão demonstrou a importância de definir um limite de
repetição e distinguir erro de credenciais de expiração de sessão. Os testes de
borda acrescentados transformaram essas regras em critérios verificáveis.

A revisão também mostrou que teste unitário aprovado não demonstra integração de
microsserviços, e que documentação extensa pode conter afirmações mais fortes que
as evidências disponíveis. Por isso, a entrega diferencia código existente,
resultado histórico, proposta de governança e homologação pendente.

O uso de IA acelerou a inspeção e a escrita, mas exigiu supervisão sobre escopo e
execução de comandos. A restrição de não executar a aplicação nem instalar pacotes
neste dispositivo passou a orientar esta etapa. Antes da apresentação, cada membro
deve acrescentar sua contribuição real, um desafio vivido e uma decisão revisada;
essa experiência coletiva não pode ser inferida apenas do código.

## 7. Evidências que o grupo deve completar

| Item | Evidência a anexar | Estado |
|---|---|---|
| Repositório oficial e entrega | Confirmação do grupo, URL e commit/tag final publicado | Pendente |
| Code review entre pares | Links de PR, autor, revisor diferente e aprovação | Pendente |
| Sprints e issues | Board/milestones, issues fechadas e vínculos com PRs | Pendente |
| Test harness completo | Logs de CI no commit final e testes integrados/backend | Pendente |
| Homologação funcional | Roteiro executado, resultado, data, versão e responsável | Pendente |
| Comparativo de IA | Experimentos e resultados reais de pelo menos duas ferramentas | Pendente |
| Relato do grupo | Contribuições e aprendizados validados pelos integrantes | Pendente |

Não fabricar commits retroativos, revisões, sprints, resultados de teste ou relatos.
