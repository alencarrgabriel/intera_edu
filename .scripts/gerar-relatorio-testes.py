"""Gera relatórios a partir dos eventos reais de flutter test --machine."""
import json
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports' / 'testes'
tests, suites, errors = {}, {}, {}
done = None
for line in (OUT / 'flutter-final.jsonl').read_text(encoding='utf-8-sig').splitlines():
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if not isinstance(event, dict):
        continue
    kind = event.get('type')
    if kind == 'suite':
        suites[event['suite']['id']] = event['suite']['path']
    elif kind == 'testStart':
        tests[event['test']['id']] = {**event['test'], 'start': event['time']}
    elif kind == 'error':
        errors.setdefault(event['testID'], []).append(event['error'])
    elif kind == 'testDone':
        tests.setdefault(event['testID'], {}).update(event)
    elif kind == 'done':
        done = event

cases = [t for t in tests.values() if t.get('name') and not t['name'].startswith('loading ')]
passed = sum(t.get('result') == 'success' and not t.get('skipped') for t in cases)
failed = sum(t.get('result') in ('failure', 'error') for t in cases)
skipped = sum(bool(t.get('skipped')) for t in cases)
pending = sum('result' not in t for t in cases)
lf = lh = 0
coverage = ROOT / 'coverage' / 'lcov.info'
if done and coverage.exists():
    for line in coverage.read_text().splitlines():
        if line.startswith('LF:'): lf += int(line[3:])
        if line.startswith('LH:'): lh += int(line[3:])
    (OUT / 'lcov.info').write_bytes(coverage.read_bytes())
summary = dict(total=len(cases), aprovados=passed, falhas=failed, ignorados=skipped,
               pendentes=pending, execucao_concluida=done is not None,
               sucesso=done.get('success') if done else None,
               linhas_cobertas=lh, linhas_instrumentadas=lf)
(OUT / 'resumo.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
xml = ET.Element('testsuite', name='InteraEdu Flutter', tests=str(len(cases)), failures=str(failed), skipped=str(skipped))
rows = []
for t in cases:
    name = t['name']
    status = 'IGNORADO' if t.get('skipped') else {'success': 'APROVADO', 'failure': 'FALHA', 'error': 'ERRO'}.get(t.get('result'), 'INCOMPLETO')
    case = ET.SubElement(xml, 'testcase', name=name, classname=suites.get(t.get('suiteID'), ''), time=str(max(0, t.get('time', t['start']) - t['start']) / 1000))
    if status in ('FALHA', 'ERRO'):
        ET.SubElement(case, 'failure').text = '\n'.join(errors.get(t['id'], []))
    elif status in ('IGNORADO', 'INCOMPLETO'):
        ET.SubElement(case, 'skipped', message=status)
    rows.append(f"| {name.replace('|', '/')} | {status} |")
ET.ElementTree(xml).write(OUT / 'junit.xml', encoding='utf-8', xml_declaration=True)
stamp = datetime.now(ZoneInfo('America/Sao_Paulo')).isoformat(timespec='seconds')
text = f'''# Relatório de testes — InteraEdu

Gerado em {stamp}.

## Resultado do aplicativo Flutter

- Execução concluída: {'sim' if done else 'não'}.
- Casos: {len(cases)}; aprovados: {passed}; falhas: {failed}; ignorados: {skipped}; incompletos: {pending}.
- Cobertura de linhas instrumentadas: {f'{lh / lf:.2%} ({lh}/{lf})' if lf else 'indisponível'}. Não representa cobertura de requisitos ou do backend.
- Comando: `flutter test --no-pub --coverage --machine` (executado diretamente pelo SDK local).

## Backend

Execução bloqueada: os seis workspaces invocam Jest, mas as dependências não estão instaladas (`jest` não encontrado). Nenhum arquivo de teste ou configuração Jest foi encontrado no backend. Isso não constitui aprovação nem falha de casos de negócio. Evidência: `backend-output.txt`.

## Escopo e limites

Foram executados os testes existentes em `test/`: modelos, autenticação, cliente HTTP, feed e widgets. Testes de bibliotecas em `vendor/` não fazem parte desta execução. Não foram executados testes ponta a ponta com PostgreSQL, Redis, SMTP, MinIO ou dispositivos reais.

O inicializador Flutter encontrou restrição de acesso ao cache do SDK; a execução final utilizou acesso autorizado ao SDK. Os arquivos `flutter-final.jsonl` e `flutter-final-errors.txt` são as evidências da execução final.

## Casos executados

| Caso | Resultado |
|---|---|
''' + '\n'.join(rows)
if errors:
    text += '\n\n## Erros capturados\n\n' + '\n\n'.join('```text\n' + '\n'.join(v) + '\n```' for v in errors.values())
text += '\n\n## Repetir a avaliação\n\nNa raiz, execute `flutter test --no-pub --coverage --machine > reports/testes/flutter-final.jsonl` e depois `python .scripts/gerar-relatorio-testes.py`. O gerador produz este relatório, resumo JSON e JUnit XML. Para avaliar o backend, é necessário instalar as dependências e implementar/configurar os testes dos serviços.\n'
(OUT / 'relatorio.md').write_text(text, encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
