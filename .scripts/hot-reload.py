"""Dispara um hot restart no Flutter web (Chrome) via Dart VM Service.

DWDS expõe `hotRestart` como serviço — não precisa de isolateId.

Uso:
    python .scripts/hot-reload.py
"""
import asyncio
import json
import os
import re
import sys
from pathlib import Path

import websockets


DEFAULT_OUTPUT = (
    "C:/Users/USER/AppData/Local/Temp/claude/"
    "C--Users-USER-Downloads-intera-edu/"
    "d563eaba-ad11-441b-a39d-787f5187da1c/tasks/b7bjvemat.output"
)


def find_vm_service_url(output_path: str) -> str | None:
    if not Path(output_path).exists():
        return None
    content = Path(output_path).read_text(errors="ignore")
    matches = re.findall(
        r"A Dart VM Service on Chrome is available at: (\S+)", content
    )
    if not matches:
        return None
    return matches[-1].strip()


async def trigger_reload(http_url: str) -> bool:
    ws_url = http_url.replace("http://", "ws://").rstrip("/") + "/ws"
    print(f"VM Service: {ws_url}", file=sys.stderr)

    async with websockets.connect(ws_url, max_size=2**24) as ws:
        # DWDS service extension — não precisa de isolateId
        await ws.send(
            json.dumps({"jsonrpc": "2.0", "id": 1, "method": "hotRestart"})
        )
        try:
            raw = await asyncio.wait_for(ws.recv(), timeout=15)
            resp = json.loads(raw)
            if "result" in resp:
                print(f"OK: {resp['result']}")
                return True
            else:
                print(f"Falha: {resp.get('error')}", file=sys.stderr)
        except asyncio.TimeoutError:
            print("Timeout", file=sys.stderr)
    return False


def main() -> int:
    output_path = os.environ.get("FLUTTER_OUTPUT", DEFAULT_OUTPUT)
    url = find_vm_service_url(output_path)
    if not url:
        print(f"VM Service URL não encontrada", file=sys.stderr)
        return 1
    ok = asyncio.run(trigger_reload(url))
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
