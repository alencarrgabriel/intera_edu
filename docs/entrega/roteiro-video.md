# Roteiro de demonstração — 3 a 5 minutos

**Apresentador:** Davi Vieira. **Duração sugerida:** 4min30s. Davi confirmou em 25/10/2026 que o vídeo já está gravado. O roteiro abaixo permanece como referência; o vídeo será enviado separadamente pelo responsável.

## Preparação

1. Usar contas fictícias e dados de demonstração; ocultar `.env`, tokens e chaves.
2. Iniciar a stack, verificar readiness e testar previamente duas contas, publicação e conversa.
3. Deixar abertos aplicativo, terminal e relatório de testes. Executar o harness uma vez antes para resolver dependências; durante a gravação executá-lo novamente.
4. Anotar o commit demonstrado e usar o mesmo commit aprovado para a release.

## Sequência

| Tempo | Mostrar | Fala sugerida |
|---|---|---|
| 0:00–0:30 | Tela inicial e identificação | “Sou Davi Vieira. O InteraEdu é uma rede social acadêmica que reúne perfis, publicações, conexões e conversas entre estudantes. A proposta é facilitar a troca de conhecimento e aproximar pessoas de diferentes instituições.” |
| 0:30–0:50 | Terminal iniciando `python .scripts/run-tests.py` | “Vou executar os testes automatizados enquanto demonstro o aplicativo. O comando compila o backend, executa as suítes e gera os relatórios de cobertura.” |
| 0:50–1:25 | Login e perfil com conta de demonstração | “O acesso utiliza uma conta institucional. Aqui estão o perfil e os dados acadêmicos. O cadastro utiliza verificação por código; nesta demonstração uso contas previamente preparadas.” |
| 1:25–2:10 | Criar publicação e visualizar feed | “Neste fluxo, publico um conteúdo e verifico sua apresentação no feed. A aplicação também permite comentários e reações.” Executar as ações somente se previamente homologadas. |
| 2:10–2:50 | Conexão e conversa entre duas contas | “A partir da conexão entre estudantes, é possível iniciar uma conversa e trocar mensagens.” Mostrar envio e recebimento real, sem simular sucesso. |
| 2:50–3:35 | Resultado do harness e relatório | Mostrar totais, ausência de falhas, cobertura e arquivos de evidência. Explicar: “Aprovação dos testes e cobertura são métricas diferentes. O relatório registra exatamente o que foi executado.” |
| 3:35–4:05 | GitHub, SDD e release | Mostrar a tag e o commit **somente após publicação**. Antes disso, apresentar como candidata, com as pendências claramente identificadas. Mostrar README e SDD As-Built. |
| 4:05–4:30 | Encerramento | “Usei Claude e ChatGPT durante o projeto. Minha maior dificuldade foi desenvolver uma aplicação mobile pela primeira vez. Aprendi que o apoio de IA precisa ser combinado com testes, documentação atualizada e revisão das entregas.” |

Se os testes demorarem mais que a janela do vídeo, iniciar aos 0:30 e continuar a demonstração. Caso seja necessário um corte, identificá-lo; não apresentar gravação antiga como execução ao vivo. Não declarar um fluxo aprovado quando o resultado real divergir.

## Registro da entrega

- Link do vídeo: **envio separado pelo responsável**.
- Data e duração: **preencher após gravação**.
- Commit/tag demonstrado: **preencher com o valor real**.
- Fluxos demonstrados: **registrar as ações efetivamente mostradas**.
