// Smoke test da stack real. Execute somente após docker compose up --wait.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const api = process.env.API_BASE_URL || 'http://localhost:3000/api/v1';
const web = process.env.WEB_BASE_URL || 'http://localhost:8080';
const cases = [
  ['liveness do gateway', `${api}/health`, {}, 200, body => assert.equal(body.status, 'ok')],
  ['readiness dos quatro serviços', `${api}/health/ready`, {}, 200, body => assert.ok(Object.values(body.services).every(Boolean))],
  ['instituições públicas', `${api}/institutions`, {}, 200],
  ['perfil exige JWT', `${api}/users/me`, {}, 401],
  ['feed exige JWT', `${api}/posts`, {}, 401],
  ['conversas exigem JWT', `${api}/chats`, {}, 401],
  ['login rejeita payload inválido', `${api}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }, 400],
  ['notificação interna exige token de serviço', `${api}/notifications/internal`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }, 401],
];
const results = [];
for (const [name, url, options, expected, verify] of cases) {
  try {
    const response = await fetch(url, { ...options, signal: AbortSignal.timeout(10000) });
    assert.equal(response.status, expected);
    if (verify) verify(await response.json());
    results.push({ name, passed: true, status: response.status });
  } catch (error) { results.push({ name, passed: false, error: error.message }); }
}
try {
  const response = await fetch(web, { signal: AbortSignal.timeout(10000) });
  assert.equal(response.status, 200);
  assert.match(await response.text(), /flutter_bootstrap\.js/);
  results.push({ name: 'frontend web servido', passed: true });
} catch (error) { results.push({ name: 'frontend web servido', passed: false, error: error.message }); }
await mkdir('reports/release', { recursive: true });
await writeFile('reports/release/docker-smoke.json', JSON.stringify({ timestamp: new Date().toISOString(), results }, null, 2));
console.log(`${results.filter(r => r.passed).length}/${results.length} verificações da stack aprovadas`);
if (results.some(r => !r.passed)) process.exitCode = 1;
