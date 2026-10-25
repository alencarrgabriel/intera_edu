# Relatório de validação da candidata à release

Execução iniciada: 25/10/2026 12:25:46. Final: 25/10/2026 12:28:30 (America/Sao_Paulo).
Commit-base: `d04d9496578b01aa9332fcb21cd07fb297854310`; branch: `master`. As alterações locais testadas estão identificadas em `source-sha256.json` e `run.json`; este registro não constitui aprovação de um commit final.

## Resultado

| Suíte | Total | Aprovados | Falhas | Ignorados |
|---|---:|---:|---:|---:|
| Flutter | 36 | 36 | 0 | 0 |
| Backend | 61 | 61 | 0 | 0 |

Harness completo aprovado: **sim**. Os códigos de saída de cada etapa estão em [run.json](./run.json).

## Cobertura

Flutter: **22.0%** das linhas instrumentadas (1285/5841).
Backend: **23.94%** das linhas incluídas; branches: **20.3%**.

A taxa de aprovação de casos é diferente da cobertura. A medição do backend inclui controllers, serviços e utilitários, inclusive arquivos sem testes; exclui bootstrap, módulos de DI, entidades, DTOs e interfaces. DTOs de login são exercitados na integração HTTP, embora não componham esse denominador.

| Unidade crítica | Linhas cobertas | Cobertura |
|---|---:|---:|
| `auth-service/src/auth/auth.service.ts` | 81/123 | 65.85% |
| `auth-service/src/auth/google-auth.service.ts` | 13/64 | 20.31% |
| `auth-service/src/otp/otp.service.ts` | 50/53 | 94.33% |
| `feed-service/src/posts/posts.service.ts` | 46/161 | 28.57% |
| `gateway/src/proxy/proxy.controller.ts` | 36/55 | 65.45% |
| `gateway/src/proxy/proxy.service.ts` | 19/23 | 82.6% |
| `messaging-service/src/chats/chats.service.ts` | 32/95 | 33.68% |
| `messaging-service/src/notifications/notifications.controller.ts` | 13/16 | 81.25% |
| `profile-service/src/connections/connections.service.ts` | 27/67 | 40.29% |
| `shared/src/auth/jwt-auth.guard.ts` | 11/11 | 100% |
| `shared/src/auth/jwt.strategy.ts` | 7/7 | 100% |
| `lib/core/network/api_client.dart` | 71/136 | 52.21% |
| `lib/core/auth/auth_notifier.dart` | 43/65 | 66.15% |
| `lib/presentation/feed/notifiers/feed_notifier.dart` | 51/81 | 62.96% |

## Escopo e limites

- Flutter: testes unitários e de widgets, sem dispositivo real.
- Backend: testes unitários com repositórios/Redis simulados; integração com servidor HTTP Nest real, validação de DTOs, JWT real e proxy para servidor HTTP local de teste.
- Não equivale a e2e com PostgreSQL, Redis, MinIO, Resend ou dispositivos reais. A execução Docker e a demonstração funcional precisam de evidência própria.
- Builds dos seis workspaces são executados pelo harness; os resultados estão em `backend-build.txt`.
- Release, proteção da main, revisão humana e gravação do vídeo não são aprovadas por este relatório.

## Casos do backend

| Caso | Resultado |
|---|---|
| Notificações internas: autenticação entre serviços rejeita token ausente/incorreto (undefined) | passed |
| Notificações internas: autenticação entre serviços rejeita token ausente/incorreto (wrong-token) | passed |
| Notificações internas: autenticação entre serviços configuração ausente falha de forma fechada | passed |
| Notificações internas: autenticação entre serviços serviço autorizado pode criar notificação | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO payload válido chega ao serviço e retorna contrato HTTP 200 | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO email inválido retorna 400 sem invocar serviço | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO campo extra é rejeitado pela whitelist | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO consentimento exige autenticação | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO liveness permanece acessível sem JWT | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO accept-terms usa identidade do JWT, ignorando user_id forjado | passed |
| Integração HTTP Nest: contrato de login e validação real de DTO revoke-consent usa identidade do JWT, ignorando user_id forjado | passed |
| JWT: assinatura e expiração com implementação real token assinado preserva identidade e instituição | passed |
| JWT: assinatura e expiração com implementação real token adulterado é rejeitado | passed |
| JWT: assinatura e expiração com implementação real token expirado é rejeitado | passed |
| Feed: autoria, reações e comentários exclusão rejeita usuário que não é autor | passed |
| Feed: autoria, reações e comentários post inexistente retorna 404 | passed |
| Feed: autoria, reações e comentários reação fora do contrato é rejeitada | passed |
| Feed: autoria, reações e comentários reação duplicada não incrementa contador | passed |
| Feed: autoria, reações e comentários comentário vazio não é persistido | passed |
| Feed: autoria, reações e comentários cache do feed isola reações e favoritos de cada usuário | passed |
| Feed: autoria, reações e comentários hashtags Unicode são normalizadas e deduplicadas | passed |
| Feed: autoria, reações e comentários menções curtas são rejeitadas e duplicatas removidas | passed |
| Conexões: permissões e transições não permite conectar consigo mesmo | passed |
| Conexões: permissões e transições não permite conectar com usuário inexistente | passed |
| Conexões: permissões e transições não cria segunda solicitação para o mesmo par | passed |
| Conexões: permissões e transições somente destinatário pode responder | passed |
| Conexões: permissões e transições conexão já resolvida não pode ser respondida novamente | passed |
| Conexões: permissões e transições destinatário pode rejeitar solicitação pendente | passed |
| Mensagens: membros, conteúdo e administração chat direto exige dois participantes distintos | passed |
| Mensagens: membros, conteúdo e administração grupo rejeita mais de 50 participantes | passed |
| Mensagens: membros, conteúdo e administração não membro não pode consultar mensagens | passed |
| Mensagens: membros, conteúdo e administração membro não pode enviar mensagem vazia sem arquivo | passed |
| Mensagens: membros, conteúdo e administração mensagem válida é normalizada e atualiza a conversa | passed |
| Mensagens: membros, conteúdo e administração somente administrador pode renomear conversa | passed |
| Mensagens: membros, conteúdo e administração persistência via WebSocket rejeita remetente externo | passed |
| AuthService: sessão e cadastro rejeita domínio não institucional sem enviar OTP | passed |
| AuthService: sessão e cadastro rejeita cadastro duplicado | passed |
| AuthService: sessão e cadastro cadastro permitido envia OTP de registro | passed |
| AuthService: sessão e cadastro OTP inválido não emite token temporário | passed |
| AuthService: sessão e cadastro token temporário usa propósito e validade de 15 minutos | passed |
| AuthService: sessão e cadastro login desconhecido é rejeitado | passed |
| AuthService: sessão e cadastro senha incorreta não cria sessão | passed |
| AuthService: sessão e cadastro login válido armazena refresh como hash | passed |
| AuthService: sessão e cadastro refresh inválido é rejeitado antes de consultar tokens | passed |
| AuthService: sessão e cadastro replay de refresh revoga a família de tokens | passed |
| AuthService: sessão e cadastro refresh válido revoga o anterior e emite novo par | passed |
| AuthService: sessão e cadastro recuperação de senha não revela conta inexistente | passed |
| Integração gateway → servidor HTTP de teste encaminha rota, query e cabeçalhos de identidade | passed |
| Integração gateway → servidor HTTP de teste normaliza erro downstream preservando status HTTP | passed |
| Integração gateway → servidor HTTP de teste rota /unknown não é encaminhada por semelhança de prefixo | passed |
| Integração gateway → servidor HTTP de teste rota /users-evil não é encaminhada por semelhança de prefixo | passed |
| Integração gateway → servidor HTTP de teste readiness consulta os serviços downstream | passed |
| Integração gateway → servidor HTTP de teste readiness retorna 503 quando um serviço está indisponível | passed |
| OTP: uso único e limites OTP ausente/expirado é rejeitado | passed |
| OTP: uso único e limites OTP válido é consumido uma única vez | passed |
| OTP: uso único e limites código incorreto incrementa tentativas | passed |
| OTP: uso único e limites quinta tentativa aciona bloqueio de 15 minutos | passed |
| OTP: uso único e limites cooldown impede verificar e consumir o código | passed |
| OTP: uso único e limites quarta solicitação por hora é rejeitada | passed |
| OTP: uso único e limites sem provedor configurado não anuncia envio bem-sucedido | passed |
| OTP: uso único e limites erro do provedor de email é propagado como indisponibilidade | passed |

## Casos Flutter

| Caso | Resultado |
|---|---|
| Connection.fromJson parseia conexão com other_user completo | success |
| CommentModel.fromJson parseia campos diretos | success |
| Connection.fromJson otherUser é null quando ausente no JSON | success |
| CommentModel.fromJson parseia author aninhado | success |
| CommentModel.fromJson parentCommentId é preservado | success |
| PostModel.fromJson parseia campos diretos (sem nested author) | success |
| PostModel.fromJson parseia objeto author aninhado | success |
| PostModel.fromJson usa defaults quando campos opcionais ausentes | success |
| login rejeitado preserva erro e não renova sessão | success |
| 401 persistente repete requisição apenas uma vez | success |
| erro com corpo inesperado é ApiException: [] | success |
| erro com corpo inesperado é ApiException: null | success |
| erro com corpo inesperado é ApiException: 42 | success |
| erro com corpo inesperado é ApiException: not json | success |
| erro com corpo inesperado é ApiException: {"message":42} | success |
| restaura identidade após renovar token: null | success |
| restaura identidade após renovar token: header.eyJzdWIiOiJleHBpcmVkIiwiZXhwIjoxLCJyb2xlcyI6WyJhZG1pbiJdfQ==.signature | success |
| restaura identidade após renovar token: invalid | success |
| token inválido sem refresh não autentica | success |
| load() popula posts e limpa erro em sucesso | success |
| load() registra erro quando getFeed lança exceção | success |
| load() hasMore é true quando há next_cursor | success |
| toggleReaction() reação otimista: sem reação → com reação, contador +1 | success |
| toggleReaction() reação otimista: com reação → sem reação, contador -1 | success |
| toggleReaction() rollback quando addReaction falha | success |
| changeScope() recarrega quando scope muda | success |
| changeScope() não recarrega quando scope não muda | success |
| CreatePostScreen botão Publicar desabilitado quando campo vazio | success |
| CreatePostScreen botão Publicar habilitado com texto preenchido | success |
| CreatePostScreen chama feedRepo.createPost ao publicar | success |
| CreatePostScreen exibe SnackBar quando createPost falha | success |
| LoginScreen renderiza campos de email e senha | success |
| App builds without errors | success |
| LoginScreen exibe erro de validação com email inválido | success |
| LoginScreen chama AuthNotifier.login com credenciais corretas | success |
| LoginScreen exibe SnackBar quando login falha | success |

## Artefatos

- [Resumo JSON](./summary.json), [JUnit](./junit.xml), [execução](./run.json), [hashes dos fontes](./source-sha256.json).
- [Flutter JSONL](./flutter-events.jsonl) e [LCOV Flutter](./flutter-lcov.info).
- [Jest JSON](./backend-tests.json), [cobertura resumida](./backend-coverage/coverage-summary.json) e [LCOV backend](./backend-coverage/lcov.info).
- Repetir: `python .scripts/run-tests.py`, com dependências instaladas. Docker: `docker compose -f compose.test.yaml run --build --rm harness`.
