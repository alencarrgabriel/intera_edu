"""Cria configuração local com segredos aleatórios, sem sobrescrever .env."""
from pathlib import Path
import secrets

root = Path(__file__).resolve().parents[1]
target = root / 'backend' / '.env'
if target.exists():
    raise SystemExit('backend/.env já existe; configuração preservada.')
values = {key: secrets.token_hex(32) for key in (
    'DATABASE_PASSWORD', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET',
    'INTERNAL_SERVICE_TOKEN', 'S3_SECRET_KEY', 'GRAFANA_ADMIN_PASSWORD')}
lines = []
for line in (root / 'backend' / '.env.example').read_text(encoding='utf-8').splitlines():
    key = line.split('=', 1)[0]
    lines.append(f'{key}={values[key]}' if key in values else line)
with target.open('x', encoding='utf-8', newline='\n') as stream:
    stream.write('\n'.join(lines) + '\n')
print('backend/.env criado. Configure RESEND_API_KEY e S3_PUBLIC_ENDPOINT antes de usar.')
