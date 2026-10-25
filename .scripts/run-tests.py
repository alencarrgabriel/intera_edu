"""Harness local/container: compila backend, executa as duas suítes e gera evidências."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports' / 'release'
OUT.mkdir(parents=True, exist_ok=True)
for name in ('backend-tests.json', 'backend-coverage/coverage-summary.json', 'backend-coverage/lcov.info', 'flutter-lcov.info'):
    (OUT / name).unlink(missing_ok=True)

def flutter_command():
    executable = shutil.which('flutter')
    if not executable:
        raise FileNotFoundError('Flutter não encontrado no PATH')
    sdk = Path(executable).resolve().parent / 'cache'
    dart = sdk / 'dart-sdk' / 'bin' / ('dart.exe' if os.name == 'nt' else 'dart')
    snapshot = sdk / 'flutter_tools.snapshot'
    # Evita o inicializador .bat no Windows; usa o mesmo SDK e suas verificações.
    if os.name == 'nt' and dart.exists() and snapshot.exists():
        return [str(dart), str(snapshot)]
    return [executable]

def execute(name, command, cwd, output, error=None):
    step = {'name': name, 'command': command, 'started_at': datetime.now(timezone.utc).isoformat()}
    try:
        with (OUT / output).open('w', encoding='utf-8') as stdout:
            if error:
                with (OUT / error).open('w', encoding='utf-8') as stderr:
                    result = subprocess.run(command, cwd=cwd, stdout=stdout, stderr=stderr, timeout=1800)
            else:
                result = subprocess.run(command, cwd=cwd, stdout=stdout, stderr=subprocess.STDOUT, timeout=1800)
        step['exit_code'] = result.returncode
    except (OSError, subprocess.TimeoutExpired) as exc:
        step.update(exit_code=1, error=str(exc))
    step['finished_at'] = datetime.now(timezone.utc).isoformat()
    print(f'{name}: código {step["exit_code"]}', flush=True)
    return step

git = ['git', '-c', f'safe.directory={ROOT.as_posix()}']
def git_output(*args):
    result = subprocess.run([*git, *args], cwd=ROOT, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None

manifest = {}
for name in ('pubspec.yaml', 'pubspec.lock', 'backend/package.json', 'backend/package-lock.json', 'backend/jest.config.cjs', 'backend/tsconfig.test.json', 'compose.yaml', 'compose.test.yaml', 'Dockerfile.test', 'Dockerfile.web'):
    manifest[name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
for folder, pattern in [('lib', '*.dart'), ('test', '*.dart'), ('backend', '*.ts'), ('backend/test', '*.js')]:
    for path in (ROOT / folder).rglob(pattern):
        if any(part in ('node_modules', 'dist', '.npm-cache') for part in path.parts) or path.name.endswith('.d.ts'):
            continue
        manifest[path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
(OUT / 'source-sha256.json').write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding='utf-8')
run = {'started_at': datetime.now(timezone.utc).isoformat(), 'head': git_output('rev-parse', 'HEAD'),
       'branch': git_output('branch', '--show-current'), 'working_tree_status': git_output('status', '--short'),
       'scope': 'Flutter unit/widgets; backend unit/HTTP integration with isolated repositories; backend builds', 'steps': []}
npm = shutil.which('npm.cmd' if os.name == 'nt' else 'npm') or 'npm'
run['steps'].append(execute('backend-build', [npm, 'run', 'build:all'], ROOT / 'backend', 'backend-build.txt'))
run['steps'].append(execute('backend-tests', [npm, 'run', 'test:coverage'], ROOT / 'backend', 'backend-output.txt'))
try:
    flutter = flutter_command()
    run['steps'].append(execute('flutter-version', [*flutter, '--version', '--machine'], ROOT, 'flutter-version.json', 'flutter-version-stderr.txt'))
    run['steps'].append(execute('flutter-tests', [*flutter, 'test', '--no-pub', '--coverage', '--machine'], ROOT, 'flutter-events.jsonl', 'flutter-stderr.txt'))
    if run['steps'][-1]['exit_code'] == 0 and (ROOT / 'coverage/lcov.info').exists():
        shutil.copyfile(ROOT / 'coverage/lcov.info', OUT / 'flutter-lcov.info')
except OSError as exc:
    run['steps'].append({'name': 'flutter-tests', 'exit_code': 1, 'error': str(exc)})
run['finished_at'] = datetime.now(timezone.utc).isoformat()
run['success'] = all(step['exit_code'] == 0 for step in run['steps'])
(OUT / 'run.json').write_text(json.dumps(run, ensure_ascii=False, indent=2), encoding='utf-8')
report = subprocess.run([sys.executable, str(ROOT / '.scripts/release-report.py')], cwd=ROOT)
raise SystemExit(0 if run['success'] and report.returncode == 0 else 1)
