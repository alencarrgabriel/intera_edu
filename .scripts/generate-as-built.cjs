// Extrai contratos declarados usando a AST TypeScript, sem iniciar os serviços.
const fs = require('node:fs');
const path = require('node:path');
const ts = require('../backend/node_modules/typescript');
const root = path.resolve(__dirname, '..');
const backend = path.join(root, 'backend');
const output = path.join(root, 'docs', 'entrega');
fs.mkdirSync(output, { recursive: true });
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const name = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(name) : [name];
  });
}
function decorators(node) {
  return (ts.canHaveDecorators(node) ? ts.getDecorators(node) || [] : []).map(d => d.expression);
}
function decorator(node, name) {
  return decorators(node).find(d => ts.isCallExpression(d) && d.expression.getText() === name);
}
const relative = file => path.relative(root, file).replaceAll('\\', '/');
const link = file => `[${relative(file)}](../../${relative(file)})`;
const escape = text => text.replaceAll('|', '\\|').replace(/\s+/g, ' ');
const files = ['shared', 'gateway', 'auth-service', 'profile-service', 'feed-service', 'messaging-service'].flatMap(service => walk(path.join(backend, service, 'src')));
const routes = [], dtos = [], entities = [];
for (const file of files.filter(file => file.endsWith('.ts'))) {
  const source = ts.createSourceFile(file, fs.readFileSync(file, 'utf8'), ts.ScriptTarget.Latest, true);
  if (file.includes(`${path.sep}dto${path.sep}`)) dtos.push(file);
  for (const node of source.statements.filter(ts.isClassDeclaration)) {
    const entity = decorator(node, 'Entity');
    if (entity) {
      entities.push({ file, name: node.name.text, table: entity.arguments.map(a => a.getText()).join(', '), fields: node.members.filter(ts.isPropertyDeclaration).map(m => `${m.name.getText()}${m.questionToken ? '?' : ''}: ${m.type?.getText() || 'inferido'}`) });
    }
    const controller = decorator(node, 'Controller');
    if (!controller) continue;
    const prefix = controller.arguments[0]?.text || '';
    for (const member of node.members.filter(ts.isMethodDeclaration)) {
      const verb = ['Get', 'Post', 'Put', 'Patch', 'Delete', 'All', 'Options', 'Head'].find(name => decorator(member, name));
      if (!verb) continue;
      const suffix = decorator(member, verb).arguments[0]?.text || '';
      const route = '/' + [prefix, suffix].filter(Boolean).join('/');
      const services = relative(file) === 'backend/shared/src/health.controller.ts'
        ? ['profile-service', 'feed-service', 'messaging-service'] : [relative(file).split('/')[1]];
      for (const service of services) routes.push({ service, verb: verb.toUpperCase(), route,
        public: Boolean(decorator(member, 'Public') || decorator(node, 'Public')),
        parameters: member.parameters.map(p => p.getText()).join('; ') || '—',
        status: decorator(member, 'HttpCode')?.arguments[0]?.getText() || (verb === 'Post' ? '201 (padrão Nest)' : '200 (padrão Nest)'),
        handler: `${node.name.text}.${member.name.getText()}`, source: relative(file) });
    }
  }
}
const lines = ['# Contratos HTTP As-Built', '',
  'Inventário extraído da AST dos controllers da árvore de trabalho. Regenerar: `node .scripts/generate-as-built.cjs` (após `npm ci` em backend). As definições vinculadas são parte da especificação. A execução HTTP e os testes são descritos no relatório de validação.', '',
  'Rotas de negócio são acessadas pelo gateway com prefixo `/api/v1`. As linhas abaixo mostram o caminho no serviço; gateway tem prefixo próprio. `@Public` dispensa o guard JWT, mas não necessariamente outras verificações (ex.: token de serviço em notifications/internal). O gateway encaminha a autenticação; os guards dos serviços a validam.', '',
  'Status padrão é o declarado pelo Nest; handlers que manipulam `@Res`, lançam exceções ou retornam outro status prevalecem. Tipos inline e `any` não recebem automaticamente validação class-validator; os DTOs abaixo identificam os contratos que possuem validação declarativa.', '',
  '| Serviço | Método | Caminho no serviço | Dispensa JWT via @Public | Status declarado | Handler e fonte |', '|---|---|---|---|---|---|'];
for (const r of routes) lines.push(`| ${r.service} | ${r.verb} | \`${r.route}\` | ${r.public ? 'sim' : 'não marcado'} | ${r.status} | [${r.handler}](../../${r.source}) |`);
lines.push('', '## Entradas declaradas por handler', '', '| Handler | Parâmetros, tipos e decorators |', '|---|---|');
for (const r of routes) lines.push(`| ${r.service}: ${r.handler} | \`${escape(r.parameters)}\` |`);
lines.push('', '## DTOs e regras de validação', '', 'As definições abaixo são extraídas do código entregue; para corpos inline, consulte a assinatura e o controller correspondente.');
for (const file of dtos) lines.push('', `### ${relative(file)}`, '', link(file), '', '```typescript', fs.readFileSync(file, 'utf8').trim(), '```');
fs.writeFileSync(path.join(output, 'contratos-as-built.md'), lines.join('\n') + '\n');
const data = ['# Modelos de persistência As-Built', '',
  'Extraído das entidades TypeORM. A anotação Entity e as propriedades abaixo identificam a estrutura entregue; decorators de coluna, índices, relações e nulabilidade de banco constam dos arquivos vinculados. Não se trata de um dump do banco em execução.', '',
  'Os schemas são criados por `backend/scripts/init-db.sql`. Em desenvolvimento, TypeORM usa synchronize; não existe comprovação de migrações de produção completas.'];
for (const e of entities) data.push('', `## ${e.name}`, '', `${link(e.file)} — \`@Entity(${escape(e.table)})\``, '', '```typescript', ...e.fields, '```');
fs.writeFileSync(path.join(output, 'modelos-as-built.md'), data.join('\n') + '\n');
fs.mkdirSync(path.join(root, 'reports', 'release'), { recursive: true });
fs.writeFileSync(path.join(root, 'reports', 'release', 'api-inventory.json'), JSON.stringify(routes, null, 2));
console.log(`${routes.length} rotas, ${dtos.length} arquivos de DTO e ${entities.length} entidades documentados.`);
