# Relatório de testes — InteraEdu

Gerado em 2026-10-17T15:47:57-03:00.

## Resultado do aplicativo Flutter

- Execução concluída: sim.
- Casos: 36; aprovados: 36; falhas: 0; ignorados: 0; incompletos: 0.
- Cobertura de linhas instrumentadas: 22.00% (1285/5841). Não representa cobertura de requisitos ou do backend.
- Comando: `flutter test --no-pub --coverage --machine` (executado diretamente pelo SDK local).

## Backend

Execução bloqueada: os seis workspaces invocam Jest, mas as dependências não estão instaladas (`jest` não encontrado). Nenhum arquivo de teste ou configuração Jest foi encontrado no backend. Isso não constitui aprovação nem falha de casos de negócio. Evidência: `backend-output.txt`.

## Escopo e limites

Foram executados os testes existentes em `test/`: modelos, autenticação, cliente HTTP, feed e widgets. Testes de bibliotecas em `vendor/` não fazem parte desta execução. Não foram executados testes ponta a ponta com PostgreSQL, Redis, SMTP, MinIO ou dispositivos reais.

O inicializador Flutter encontrou restrição de acesso ao cache do SDK; a execução final utilizou acesso autorizado ao SDK. Os arquivos `flutter-final.jsonl` e `flutter-final-errors.txt` são as evidências da execução final.

## Casos executados

| Caso | Resultado |
|---|---|
| Connection.fromJson parseia conexão com other_user completo | APROVADO |
| PostModel.fromJson parseia campos diretos (sem nested author) | APROVADO |
| CommentModel.fromJson parseia campos diretos | APROVADO |
| Connection.fromJson otherUser é null quando ausente no JSON | APROVADO |
| PostModel.fromJson parseia objeto author aninhado | APROVADO |
| CommentModel.fromJson parseia author aninhado | APROVADO |
| CommentModel.fromJson parentCommentId é preservado | APROVADO |
| PostModel.fromJson usa defaults quando campos opcionais ausentes | APROVADO |
| login rejeitado preserva erro e não renova sessão | APROVADO |
| 401 persistente repete requisição apenas uma vez | APROVADO |
| erro com corpo inesperado é ApiException: [] | APROVADO |
| erro com corpo inesperado é ApiException: null | APROVADO |
| erro com corpo inesperado é ApiException: 42 | APROVADO |
| erro com corpo inesperado é ApiException: not json | APROVADO |
| erro com corpo inesperado é ApiException: {"message":42} | APROVADO |
| restaura identidade após renovar token: null | APROVADO |
| restaura identidade após renovar token: header.eyJzdWIiOiJleHBpcmVkIiwiZXhwIjoxLCJyb2xlcyI6WyJhZG1pbiJdfQ==.signature | APROVADO |
| restaura identidade após renovar token: invalid | APROVADO |
| token inválido sem refresh não autentica | APROVADO |
| load() popula posts e limpa erro em sucesso | APROVADO |
| load() registra erro quando getFeed lança exceção | APROVADO |
| load() hasMore é true quando há next_cursor | APROVADO |
| toggleReaction() reação otimista: sem reação → com reação, contador +1 | APROVADO |
| toggleReaction() reação otimista: com reação → sem reação, contador -1 | APROVADO |
| toggleReaction() rollback quando addReaction falha | APROVADO |
| changeScope() recarrega quando scope muda | APROVADO |
| changeScope() não recarrega quando scope não muda | APROVADO |
| CreatePostScreen botão Publicar desabilitado quando campo vazio | APROVADO |
| CreatePostScreen botão Publicar habilitado com texto preenchido | APROVADO |
| CreatePostScreen chama feedRepo.createPost ao publicar | APROVADO |
| CreatePostScreen exibe SnackBar quando createPost falha | APROVADO |
| LoginScreen renderiza campos de email e senha | APROVADO |
| App builds without errors | APROVADO |
| LoginScreen exibe erro de validação com email inválido | APROVADO |
| LoginScreen chama AuthNotifier.login com credenciais corretas | APROVADO |
| LoginScreen exibe SnackBar quando login falha | APROVADO |

## Repetir a avaliação

Na raiz, execute `flutter test --no-pub --coverage --machine > reports/testes/flutter-final.jsonl` e depois `python .scripts/gerar-relatorio-testes.py`. O gerador produz este relatório, resumo JSON e JUnit XML. Para avaliar o backend, é necessário instalar as dependências e implementar/configurar os testes dos serviços.
