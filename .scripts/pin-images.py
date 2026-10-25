"""Resolve imagens públicas para digests imutáveis. Requer rede e revisão do diff."""
import json
from pathlib import Path
import re
from urllib.request import Request, urlopen
from urllib.parse import urlencode

root = Path(__file__).resolve().parents[1]
files = [root / 'Dockerfile.web', root / 'Dockerfile.test', root / 'backend/docker-compose.yml', *sorted((root / 'backend').glob('*/Dockerfile'))]
pattern = re.compile(r'(?m)^(?:FROM |\s+image: )([^\s]+)')
images = sorted({m.group(1) for file in files for m in pattern.finditer(file.read_text())})
locked = {}
for image in images:
    print(f'Verificando {image}', flush=True)
    if '@sha256:' in image:
        locked[image.split('@')[0]] = image
        continue
    if image.startswith('ghcr.io/'):
        repository, tag = image.removeprefix('ghcr.io/').rsplit(':', 1)
        registry, auth, service = 'https://ghcr.io', 'https://ghcr.io/token', 'ghcr.io'
    else:
        repository, _, tag = image.partition(':')
        if '/' not in repository: repository = 'library/' + repository
        tag = tag or 'latest'
        registry, auth, service = 'https://registry-1.docker.io', 'https://auth.docker.io/token', 'registry.docker.io'
    with urlopen(auth + '?' + urlencode({'service': service, 'scope': f'repository:{repository}:pull'}), timeout=30) as response:
        token = json.load(response)['token']
    request = Request(f'{registry}/v2/{repository}/manifests/{tag}', headers={
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json',
    })
    with urlopen(request, timeout=30) as response:
        digest = response.headers['Docker-Content-Digest']
    if not digest or not re.fullmatch(r'sha256:[0-9a-f]{64}', digest): raise RuntimeError('Digest inválido')
    locked[image] = image + '@' + digest
for file in files:
    source = file.read_text(encoding='utf-8')
    source = pattern.sub(lambda m: m.group(0).replace(m.group(1), locked.get(m.group(1), m.group(1))), source)
    file.write_text(source, encoding='utf-8')
(root / 'deploy/images.lock.json').write_text(json.dumps(locked, indent=2) + '\n', encoding='utf-8')
print(f'{len(locked)} referências fixadas por digest; imagens não foram executadas.')
