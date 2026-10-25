"""Verifica arquivos versionáveis; relata somente localização, nunca o segredo."""
from pathlib import Path
import json
import re
import subprocess

root = Path(__file__).resolve().parents[1]
command = ['git', '-c', f'safe.directory={root.as_posix()}', 'ls-files', '--cached', '--others', '--exclude-standard', '-z']
result = subprocess.run(command, cwd=root, capture_output=True, check=True)
files = sorted(set(result.stdout.decode('utf-8').split('\0')) - {''})
patterns = {
    'chave privada': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'token GitHub': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})\b'),
    'access key AWS': re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
    'chave Resend': re.compile(r'\bre_[A-Za-z0-9]{30,}\b'),
}
findings, checked = [], 0
for name in files:
    file = root / name
    if not file.is_file() or name.startswith('reports/'):
        continue
    if file.name.startswith('.env') and file.name != '.env.example':
        findings.append({'file': name, 'rule': 'arquivo de ambiente versionável'})
    if file.name.endswith(('.tsbuildinfo', '.pyc')) or '/node_modules/' in name or name.startswith('android/build/'):
        findings.append({'file': name, 'rule': 'artefato temporário/gerado versionável'})
    if '/src/' in name and file.suffix == '.js' and file.with_suffix('.ts').exists():
        findings.append({'file': name, 'rule': 'JavaScript compilado junto ao TypeScript'})
    try: source = file.read_text(encoding='utf-8')
    except (UnicodeError, OSError): continue
    checked += 1
    for number, line in enumerate(source.splitlines(), 1):
        for rule, pattern in patterns.items():
            if pattern.search(line): findings.append({'file': name, 'line': number, 'rule': rule})
report = {'scope': 'Arquivos versionados e novos não ignorados da árvore atual; relatórios e histórico Git não inspecionados.',
          'files_checked': checked, 'findings': findings,
          'limitation': 'Busca por padrões conhecidos; não certifica ausência universal de segredos nem substitui revisão humana.'}
out = root / 'reports/release'
out.mkdir(parents=True, exist_ok=True)
(out / 'hygiene.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'{checked} arquivos textuais verificados; {len(findings)} ocorrências.')
for finding in findings: print(finding)
raise SystemExit(1 if findings else 0)
