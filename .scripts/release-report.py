"""Consolida resultados reais. Sucesso dos testes não equivale a homologação da release."""
import json
from pathlib import Path
from datetime import datetime, timedelta, timezone
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/release'
def read_json(name, default):
    path = OUT / name
    return json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else default
run = read_json('run.json', {})
backend = read_json('backend-tests.json', {})
coverage = read_json('backend-coverage/coverage-summary.json', {})
tests, errors, final = {}, {}, None
path = OUT / 'flutter-events.jsonl'
if path.exists():
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        try: event = json.loads(line)
        except ValueError: continue
        if not isinstance(event, dict): continue
        kind = event.get('type')
        if kind == 'testStart': tests[event['test']['id']] = {**event['test'], 'start': event['time']}
        elif kind == 'testDone': tests.setdefault(event['testID'], {}).update(event)
        elif kind == 'error': errors.setdefault(event['testID'], []).append(event['error'])
        elif kind == 'done': final = event
cases = [t for t in tests.values() if t.get('name') and not t['name'].startswith('loading ')]
flutter = {'total': len(cases), 'passed': sum(t.get('result') == 'success' and not t.get('skipped') for t in cases),
           'failed': sum(t.get('result') in ('failure', 'error') for t in cases),
           'skipped': sum(bool(t.get('skipped')) for t in cases), 'success': bool(final and final.get('success'))}
lcov, current = {}, None
path = OUT / 'flutter-lcov.info'
if path.exists():
    for line in path.read_text().splitlines():
        if line.startswith('SF:'):
            current = line[3:].replace('\\', '/')
            lcov[current] = {'covered': 0, 'total': 0}
        elif current and line.startswith('LF:'): lcov[current]['total'] = int(line[3:])
        elif current and line.startswith('LH:'): lcov[current]['covered'] = int(line[3:])
covered, total = sum(v['covered'] for v in lcov.values()), sum(v['total'] for v in lcov.values())
flutter['coverage'] = {'covered': covered, 'total': total, 'pct': round(covered / total * 100, 2) if total else None}
summary = {'flutter': flutter,
    'backend': {'total': backend.get('numTotalTests'), 'passed': backend.get('numPassedTests'), 'failed': backend.get('numFailedTests'), 'skipped': backend.get('numPendingTests'), 'success': backend.get('success', False), 'coverage': coverage.get('total', {})},
    'harness_success': bool(run.get('success') and flutter['success'] and backend.get('success')),
    'release_approved': False}
(OUT / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
xml = ET.Element('testsuites')
fs = ET.SubElement(xml, 'testsuite', name='Flutter', tests=str(len(cases)), failures=str(flutter['failed']))
for t in cases:
    case = ET.SubElement(fs, 'testcase', name=t['name'], time=str(max(0, t.get('time', t['start']) - t['start']) / 1000))
    if t.get('result') in ('failure', 'error'): ET.SubElement(case, 'failure').text = '\n'.join(errors.get(t['id'], []))
    elif t.get('skipped') or 'result' not in t: ET.SubElement(case, 'skipped')
for suite in backend.get('testResults', []):
    element = ET.SubElement(xml, 'testsuite', name=Path(suite['name']).name)
    for t in suite.get('assertionResults', []):
        case = ET.SubElement(element, 'testcase', name=t['fullName'], time=str((t.get('duration') or 0) / 1000))
        if t['status'] == 'failed': ET.SubElement(case, 'failure').text = '\n'.join(t.get('failureMessages', []))
        elif t['status'] != 'passed': ET.SubElement(case, 'skipped')
ET.ElementTree(xml).write(OUT / 'junit.xml', encoding='utf-8', xml_declaration=True)
def local_time(value):
    return datetime.fromisoformat(value).astimezone(timezone(timedelta(hours=-3))).strftime('%d/%m/%Y %H:%M:%S') if value else 'não registrado'
lines = ['# Relatório de validação da candidata à release', '',
    f"Execução iniciada: {local_time(run.get('started_at'))}. Final: {local_time(run.get('finished_at'))} (America/Sao_Paulo).",
    f"Commit-base: `{run.get('head')}`; branch: `{run.get('branch')}`. As alterações locais testadas estão identificadas em `source-sha256.json` e `run.json`; este registro não constitui aprovação de um commit final.", '',
    '## Resultado', '', '| Suíte | Total | Aprovados | Falhas | Ignorados |', '|---|---:|---:|---:|---:|',
    f"| Flutter | {flutter['total']} | {flutter['passed']} | {flutter['failed']} | {flutter['skipped']} |",
    f"| Backend | {backend.get('numTotalTests', 'N/D')} | {backend.get('numPassedTests', 'N/D')} | {backend.get('numFailedTests', 'N/D')} | {backend.get('numPendingTests', 'N/D')} |", '',
    f"Harness completo aprovado: **{'sim' if summary['harness_success'] else 'não'}**. Os códigos de saída de cada etapa estão em [run.json](./run.json).", '',
    '## Cobertura', '',
    f"Flutter: **{flutter['coverage']['pct']}%** das linhas instrumentadas ({covered}/{total}).",
    f"Backend: **{coverage.get('total', {}).get('lines', {}).get('pct', 'N/D')}%** das linhas incluídas; branches: **{coverage.get('total', {}).get('branches', {}).get('pct', 'N/D')}%**.", '',
    'A taxa de aprovação de casos é diferente da cobertura. A medição do backend inclui controllers, serviços e utilitários, inclusive arquivos sem testes; exclui bootstrap, módulos de DI, entidades, DTOs e interfaces. DTOs de login são exercitados na integração HTTP, embora não componham esse denominador.', '',
    '| Unidade crítica | Linhas cobertas | Cobertura |', '|---|---:|---:|']
critical = ('auth.service.ts', 'otp.service.ts', 'jwt-auth.guard.ts', 'jwt.strategy.ts', 'proxy.service.ts', 'proxy.controller.ts', 'connections.service.ts', 'posts.service.ts', 'chats.service.ts', 'notifications.controller.ts')
for name, metrics in coverage.items():
    if name == 'total' or not name.endswith(critical): continue
    item = metrics['lines']
    label = name.replace('\\', '/').split('/backend/')[-1]
    lines.append(f"| `{label}` | {item['covered']}/{item['total']} | {item['pct']}% |")
for name, item in lcov.items():
    if name.endswith(('auth_notifier.dart', 'api_client.dart', 'feed_notifier.dart')):
        pct = round(item['covered'] / item['total'] * 100, 2) if item['total'] else 0
        lines.append(f"| `{name}` | {item['covered']}/{item['total']} | {pct}% |")
lines += ['', '## Escopo e limites', '',
    '- Flutter: testes unitários e de widgets, sem dispositivo real.',
    '- Backend: testes unitários com repositórios/Redis simulados; integração com servidor HTTP Nest real, validação de DTOs, JWT real e proxy para servidor HTTP local de teste.',
    '- Não equivale a e2e com PostgreSQL, Redis, MinIO, Resend ou dispositivos reais. A execução Docker e a demonstração funcional precisam de evidência própria.',
    '- Builds dos seis workspaces são executados pelo harness; os resultados estão em `backend-build.txt`.',
    '- Release, proteção da main, revisão humana e gravação do vídeo não são aprovadas por este relatório.', '',
    '## Casos do backend', '', '| Caso | Resultado |', '|---|---|']
for suite in backend.get('testResults', []):
    for t in suite.get('assertionResults', []): lines.append(f"| {t['fullName'].replace('|', '/')} | {t['status']} |")
lines += ['', '## Casos Flutter', '', '| Caso | Resultado |', '|---|---|']
for t in cases: lines.append(f"| {t['name'].replace('|', '/')} | {t.get('result', 'incompleto')} |")
lines += ['', '## Artefatos', '',
    '- [Resumo JSON](./summary.json), [JUnit](./junit.xml), [execução](./run.json), [hashes dos fontes](./source-sha256.json).',
    '- [Flutter JSONL](./flutter-events.jsonl) e [LCOV Flutter](./flutter-lcov.info).',
    '- [Jest JSON](./backend-tests.json), [cobertura resumida](./backend-coverage/coverage-summary.json) e [LCOV backend](./backend-coverage/lcov.info).',
    '- Repetir: `python .scripts/run-tests.py`, com dependências instaladas. Docker: `docker compose -f compose.test.yaml run --build --rm harness`.', '']
(OUT / 'relatorio.md').write_text('\n'.join(lines), encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
