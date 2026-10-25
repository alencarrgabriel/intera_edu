# Checklist de entrega e liberação

Revisão: 25/10/2026. Responsável: Davi Vieira. A candidata local ainda não é uma release oficial publicada.

| Exigência | Evidência / situação |
|---|---|
| Especificação As-Built | [SDD](./sdd-as-built.md), contratos extraídos e modelos de persistência preparados. |
| Suíte 100% pass | [Relatório local](../../reports/release/relatorio.md). A aprovação se refere aos casos executados, não a todos os requisitos funcionais. |
| Cobertura de módulos críticos | Relatório por unidade e arquivos LCOV/Jest/JSON em `reports/release`. |
| Código higienizado | Scan de padrões na árvore atual, remoção de caches/cópias compiladas e segredos obrigatórios via ambiente. Revisão humana e histórico Git não certificados pelo scan. |
| Aplicação/harness com comando único | Stack executada no GitHub Actions: todos os serviços saudáveis, 9/9 smoke checks e 97/97 testes em container. [Evidências](../../reports/release/ci/docker/provenance.json). |
| README final | Guia de ambiente, execução, testes, evidências e limites atualizado. |
| PRs abertos | Entrega acompanhada no [PR #12](https://github.com/alencarrgabriel/intera_edu/pull/12); conferir integração e zero PRs antes da tag. |
| main consolidada/protegida | GitHub ainda usa **master sem proteção**; não há main. O proprietário configurará a main e suas regras, conforme orientação de Davi. |
| Tag/release oficial | Nenhuma release na consulta. Workflow de publicação preparado; ainda não executado. |
| Vídeo de 3–5 minutos | Gravação concluída, conforme confirmação de Davi. Envio separado pelo responsável, conforme sua orientação. |
| Retrospectiva | [Texto](./retrospectiva.md) preparado com o relato fornecido; revisão pessoal pendente. |

## Fechar o pacote local

1. Revisar as alterações de código e os limites declarados no SDD.
2. Instalar dependências com lockfile; executar `python .scripts/run-tests.py`.
3. Em host com Docker, executar `docker compose --env-file backend/.env up --build -d --wait`, depois `node .scripts/smoke-test.mjs` e `docker compose -f compose.test.yaml run --build --rm harness`.
4. Homologar cadastro/OTP com provedor configurado, criação de perfil, login/logout, privacidade entre contas, publicação/anexo, conexão e mensagem entre dois clientes. Registrar esperado, obtido e evidência. O smoke test não substitui esses fluxos.
5. Enviar o vídeo separadamente, conforme orientação de Davi; revisar a retrospectiva.

## Consolidar no GitHub

1. Revisar/commitar os arquivos preparados em branch de entrega; abrir PR para a branch principal existente. Não sobrescrever o histórico nem encerrar PRs sem revisão.
2. Após os checks e a revisão do responsável, integrar a entrega. Migrar/renomear `master` para **main** nas configurações do repositório, preservando o histórico; definir `main` como padrão.
3. Configurar ruleset/branch protection para `main`: impedir force push e exclusão, exigir checks **Harness Flutter e backend** e **Stack Docker e smoke test**, exigir resolução de conversas e revisão humana compatível com os colaboradores disponíveis. Davi é o único integrante informado; revisão independente requer convidar um revisor, não fabricar aprovação.
4. Configurar o environment **release** com aprovação humana quando disponível. Verificar que não restam PRs abertos nem conflitos. Guardar a evidência das regras e da revisão.
5. Executar **Publicar release aprovada** na branch `main`, informando `v1.0.0` (se livre) e o SHA completo aprovado. O workflow reexecuta validação, exige main protegida, SHA correspondente e zero PRs abertos. Ele cria uma release em rascunho, anexa evidências e publica após o upload; não sobrescreve uma tag existente.
6. Conferir URL da release, tag apontando para o SHA aprovado, conteúdo do ZIP, Actions verdes e vídeo. Atualizar a tabela de aceite com essas evidências.

O workflow não cria proteção nem fornece uma aprovação humana por conta própria. A conexão GitHub com permissões apropriadas é necessária para executar essas ações pela assistência; a consulta pública já realizada não concede acesso de escrita.

## Registro de aceite

| Campo | Valor |
|---|---|
| SHA final aprovado na main | Pendente |
| Responsável/data da aprovação | Pendente |
| URL dos checks do commit final | Pendente |
| Evidência de proteção da main | Pendente |
| URL da release/tag | Pendente |
| Vídeo | Gravado; envio separado por Davi |
| Evidências dos fluxos homologados | Pendente |
