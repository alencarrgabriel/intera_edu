"""Relatório da Entrega 2 com dados reais de reports/release (ReportLab)."""
from pathlib import Path
import json
from html import escape
from collections import Counter
from reportlab.pdfgen import canvas
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Flowable, Preformatted
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/pdf'
OUT.mkdir(parents=True, exist_ok=True)
DATA = ROOT / 'reports/release'
summary = json.loads((DATA / 'summary.json').read_text(encoding='utf-8'))
run = json.loads((DATA / 'run.json').read_text(encoding='utf-8'))
backend = json.loads((DATA / 'backend-tests.json').read_text(encoding='utf-8'))
cov = json.loads((DATA / 'backend-coverage/coverage-summary.json').read_text(encoding='utf-8'))
github = json.loads((DATA / 'github-state.json').read_text(encoding='utf-8-sig'))
GREEN = colors.HexColor('#176449')
DARK = colors.HexColor('#143A32')
INK = colors.HexColor('#203531')
MUTED = colors.HexColor('#586D66')
PALE = colors.HexColor('#EEF5F0')
LINE = colors.HexColor('#D7E4DC')
AMBER = colors.HexColor('#8F5A17')
W = A4[0] - 92

for name, file in [('Body', 'arial.ttf'), ('Body-Bold', 'arialbd.ttf'), ('Body-Italic', 'ariali.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + file))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Body-Bold', italic='Body-Italic', boldItalic='Body-Bold')
styles = {
    'body': ParagraphStyle('body', fontName='Body', fontSize=10.3, leading=15.2, textColor=INK, spaceAfter=9),
    'small': ParagraphStyle('small', fontName='Body', fontSize=8.8, leading=12.5, textColor=MUTED, spaceAfter=7),
    'h1': ParagraphStyle('h1', fontName='Body-Bold', fontSize=23, leading=28, textColor=DARK, spaceAfter=14),
    'h2': ParagraphStyle('h2', fontName='Body-Bold', fontSize=12.5, leading=17, textColor=GREEN, spaceBefore=10, spaceAfter=7),
    'eyebrow': ParagraphStyle('eyebrow', fontName='Body-Bold', fontSize=9, leading=13, textColor=GREEN, spaceAfter=7),
    'cell': ParagraphStyle('cell', fontName='Body', fontSize=8.8, leading=12.3, textColor=INK),
    'headcell': ParagraphStyle('headcell', fontName='Body-Bold', fontSize=8.7, leading=12.2, textColor=colors.white),
    'quote': ParagraphStyle('quote', fontName='Body-Italic', fontSize=13, leading=20, textColor=DARK, leftIndent=12, rightIndent=12, spaceAfter=12),
    'code': ParagraphStyle('code', fontName='Courier', fontSize=8.1, leading=12, textColor=DARK, backColor=PALE, borderPadding=9, spaceAfter=12),
}
story = []
def clean(text): return text.replace('\u2014', ' - ').replace('\u2013', '-').replace('\u2011', '-')
def P(text, style='body'): return Paragraph(clean(text), styles[style])
def p(text, style='body'): story.append(P(text, style))
def h2(text): p(text, 'h2')
def space(n=6): story.append(Spacer(1,n))
def section(label, title, anchor):
    if story: story.append(PageBreak())
    p(label.upper(), 'eyebrow')
    paragraph = P(title, 'h1')
    paragraph.bookmark = anchor
    story.append(paragraph)
def table(headers, rows, widths=None):
    values = [[P(x,'headcell') for x in headers]] + [[P(str(x),'cell') for x in row] for row in rows]
    t = Table(values, colWidths=widths or [W/len(headers)]*len(headers), repeatRows=1, hAlign='LEFT')
    t.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),DARK),('VALIGN',(0,0),(-1,-1),'TOP'),
        ('LEFTPADDING',(0,0),(-1,-1),9),('RIGHTPADDING',(0,0),(-1,-1),9),
        ('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,PALE]),
        ('LINEBELOW',(0,0),(-1,0),0.6,GREEN),('LINEBELOW',(0,1),(-1,-1),0.35,LINE),
    ]))
    story.append(t); space(10)
def note(title,text):
    t=Table([[P(title,'h2')],[P(text,'body')]], colWidths=[W])
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),PALE),('BOX',(0,0),(-1,-1),0.5,LINE),('LEFTPADDING',(0,0),(-1,-1),12),('RIGHTPADDING',(0,0),(-1,-1),12),('TOPPADDING',(0,0),(-1,0),2),('BOTTOMPADDING',(0,-1),(-1,-1),7)]))
    story.append(KeepTogether([t,Spacer(1,10)]))
def code(text): story.append(Preformatted(text,styles['code']))
def evidence(text): p('<b>Evidências:</b> '+text,'small')

class Hero(Flowable):
    def __init__(self): super().__init__(); self.width=W; self.height=210
    def draw(self):
        c=self.canv; c.setFillColor(DARK); c.roundRect(0,0,W,210,12,fill=1,stroke=0)
        c.setFillColor(colors.HexColor('#91C8A7')); c.setFont('Body-Bold',10); c.drawString(24,175,'PROJETO INTERAEDU')
        c.setFillColor(colors.white); c.setFont('Body-Bold',37); c.drawString(24,118,'Da fundação ao')
        c.drawString(24,73,'produto defendido')
        c.setFont('Body',11); c.setFillColor(colors.HexColor('#D8EBDF')); c.drawString(24,28,'Especificação, implementação, testes e governança')

class Architecture(Flowable):
    def __init__(self): super().__init__(); self.width=W; self.height=290
    def draw(self):
        c=self.canv
        def box(x,y,w,h,title,detail=''):
            c.setFillColor(PALE);c.setStrokeColor(LINE);c.roundRect(x,y,w,h,6,fill=1,stroke=1)
            c.setFillColor(DARK);c.setFont('Body-Bold',10);c.drawCentredString(x+w/2,y+h-18,title)
            if detail:c.setFillColor(MUTED);c.setFont('Body',8);c.drawCentredString(x+w/2,y+12,detail)
        def arrow(x1,y1,x2,y2):
            from math import atan2,cos,sin,pi
            c.setStrokeColor(GREEN);c.setLineWidth(1.1);c.line(x1,y1,x2,y2)
            a=atan2(y2-y1,x2-x1);p=c.beginPath();p.moveTo(x2,y2);p.lineTo(x2-6*cos(a-pi/6),y2-6*sin(a-pi/6));p.lineTo(x2-6*cos(a+pi/6),y2-6*sin(a+pi/6));p.close();c.setFillColor(GREEN);c.drawPath(p,fill=1,stroke=0)
        box(0,228,148,52,'Flutter','Mobile / web')
        box(202,228,152,52,'Gateway :3000','REST /api/v1')
        arrow(148,254,202,254)
        xs=[0,129,258,387]
        for x,title,port in zip(xs,['Auth','Profile','Feed','Messaging'],['3001','3002','3003','3004']):
            box(x,130,116,55,title,':'+port)
            arrow(278,228,x+58,185)
        c.setFont('Body',8);c.setFillColor(MUTED);c.drawString(7,204,'Socket.IO /ws direto no Messaging')
        box(0,20,165,55,'PostgreSQL 16','Schemas por domínio + audit')
        box(180,20,143,55,'Redis 7','OTP, cache, Pub/Sub')
        box(338,20,165,55,'MinIO / S3','Arquivos e URLs de mídia')
        arrow(58,130,80,75);arrow(187,130,105,75);arrow(316,130,251,75);arrow(445,130,419,75)

class CoverageBars(Flowable):
    def __init__(self): super().__init__();self.width=W;self.height=95
    def draw(self):
        c=self.canv
        for y,name,value in [(61,'Flutter',summary['flutter']['coverage']['pct']),(17,'Backend',summary['backend']['coverage']['lines']['pct'])]:
            c.setFont('Body-Bold',10);c.setFillColor(DARK);c.drawString(0,y+13,name)
            c.setFillColor(PALE);c.roundRect(97,y,335,22,4,fill=1,stroke=0)
            c.setFillColor(GREEN);c.roundRect(97,y,335*value/100,22,4,fill=1,stroke=0)
            c.setFont('Body-Bold',10);c.drawRightString(W,y+6,f'{value:.2f}%'.replace('.',','))

class Report(SimpleDocTemplate):
    def afterFlowable(self, flowable):
        if hasattr(flowable,'bookmark'):
            self.canv.bookmarkPage(flowable.bookmark)
            self.canv.addOutlineEntry(flowable.getPlainText(),flowable.bookmark,level=0,closed=False)

def page_frame(c,doc):
    c.saveState()
    if doc.page>1:
        c.setFont('Body-Bold',8);c.setFillColor(GREEN);c.drawString(46,A4[1]-29,'INTERAEDU / ENTREGA 2')
        c.setFont('Body',8);c.setFillColor(MUTED);c.drawRightString(A4[0]-46,A4[1]-29,'25 OUT 2026')
        c.setStrokeColor(LINE);c.line(46,A4[1]-37,A4[0]-46,A4[1]-37)
    c.setStrokeColor(LINE);c.line(46,38,A4[0]-46,38)
    c.setFont('Body',8);c.setFillColor(MUTED);c.drawString(46,24,'Davi Vieira | Relatório técnico e acadêmico')
    c.drawRightString(A4[0]-46,24,str(doc.page))
    c.restoreState()

# Capa
space(23); p('ENTREGA 2 / RELATÓRIO CONSOLIDADO','eyebrow'); space(9);story.append(Hero());space(23)
p('<b>Davi Vieira</b><br/>25 de outubro de 2026')
p('Rede social acadêmica com aplicação Flutter e serviços NestJS. Documento organizado pelos dez passos da entrega, com checklist e apêndice de evidências.')
table(['TESTES LOCAIS','RESULTADO','COBERTURA DE LINHAS'],[['97 casos executados','97 aprovados<br/>0 falhas / 0 ignorados','Flutter: 22,00%<br/>Backend: 23,94%']],[150,150,W-300])
note('Situação do pacote','Candidata à entrega. Testes locais e no CI aprovados; Docker validado com 9 smoke checks e 97 testes em container. A configuração da main caberá ao proprietário. A release oficial e o aceite funcional ainda dependem de conclusão. Davi confirmou o vídeo gravado e seu envio separado.')
p('Ferramentas de IA informadas: <b>Claude e ChatGPT</b>. O documento distingue relato do responsável, evidência técnica observada e atividades propostas.','small')

# 2
section('Guia de leitura','Entendendo a Entrega 2','overview')
p('A primeira entrega estabelece a fundação: problema, requisitos, arquitetura e implementação inicial. A segunda transforma essa base em uma solução que pode ser executada, testada, explicada e defendida com evidências. No InteraEdu, essa passagem foi organizada em auditoria, correções, especificação As-Built e preparação da release.')
table(['ETAPA','CONTEÚDO NESTE DOCUMENTO'],[
    ['01','Auditoria da Entrega 1 e backlog da sprint final'],['02','Solução funcional do InteraEdu e critérios de aceite'],['03','Erros lógicos, regressões e re-especificação'],['04','PRs, critérios de aceitação e governança'],['05','Instalação, arquitetura e fluxo de uso'],['06','ADRs consolidados e defesa das decisões'],['07','Relato de experiência de Davi Vieira'],['08','Matriz comparativa: Claude e ChatGPT'],['09','Relatório ético-técnico em quatro pilares'],['10','Testes, cobertura e consolidação do PDF'],['Final','Checklist, cronograma proposto e guia de evidências']],[55,W-55])
h2('Como interpretar as evidências')
p('<b>Verificado:</b> execução ou inspeção registrada. <b>Preparado:</b> artefato existente, ainda dependente de execução/aceite. <b>Pendente:</b> ação ou comprovação ausente. A ausência de evidência não é preenchida por uma afirmação presumida.')
p('Base da avaliação: repositório alencarrgabriel/intera_edu, commit-base <b>d04d949</b> e alterações locais identificadas no manifesto SHA-256. O relatório não declara que esse commit já é a versão final aprovada.','small')

# 3
section('Passo 1','Auditoria e backlog da sprint final','step1')
p('A auditoria comparou o código e os registros disponíveis com os requisitos de entrega. O documento formal original da Entrega 1 não foi fornecido nesta conversa; portanto, a comparação usa o repositório e a documentação existente como base, sem certificar aderência integral a um enunciado não consultado.')
table(['ÁREA','BASE ENCONTRADA','AVANÇO DESTA ETAPA'],[
    ['Testes','36 testes Flutter; backend sem suíte executável instalada.','61 testes backend acrescentados; harness unificado; 97 casos aprovados.'],
    ['Contratos','Documentação misturava decisões planejadas e comportamento real.','Inventário com 93 entradas de rota, 13 arquivos de DTO e 31 entidades.'],
    ['Segurança/configuração','Defaults de credenciais, consentimento por body e cache compartilhado.','Segredos via ambiente; identidade por JWT; isolamento de cache e token interno.'],
    ['Repositório','master sem proteção; artefatos compilados e caches versionados.','Limpeza local e workflows preparados; main/release ainda pendentes.'],
    ['Execução','Compose antigo, frontend separado e imagem de storage indisponível.','Compose integrado, harness em container e storage com fonte fixa; stack e testes Docker aprovados no CI.'],
],[70,200,W-270])
h2('Backlog de fechamento e situação')
table(['NÍVEL','ITEM / CRITÉRIO DE CONCLUSÃO'],[
    ['P0','Concluído no CI: stack saudável, 9/9 smoke checks e 97/97 testes em container.'],
    ['P0','Homologar cadastro/OTP, perfil, publicação, privacidade, arquivo e conversa entre duas contas.'],
    ['P0','Revisar o commit final, consolidar main protegida e publicar tag apontando para o SHA aprovado.'],
    ['P1','Enviar o vídeo separadamente e registrar links de execução e revisão.'],
    ['P1','Completar comparação empírica das IAs se exigida; revisar relato pessoal e limitações.'],
],[70,W-70])

# 4
section('Passo 2','Completando a solução funcional','step2')
p('O exemplo StudyRoom do roteiro é aplicado aqui ao produto real: <b>InteraEdu</b>. O problema trabalhado é a aproximação de universitários para compartilhar conhecimento, encontrar pessoas por interesses e manter interações acadêmicas em um ambiente institucional.')
table(['FLUXO','IMPLEMENTAÇÃO PRESENTE','ACEITE FUNCIONAL A REGISTRAR'],[
    ['Acesso institucional','Registro, OTP, login, refresh e recuperação de senha.','Cadastro com domínio permitido; rejeição de domínio/OTP inválido; sessão e logout.'],
    ['Perfil e conexões','Dados acadêmicos, habilidades, privacidade e solicitações de conexão.','Editar perfil; solicitar/aceitar/rejeitar; testar acesso de outra conta.'],
    ['Feed e publicações','Feed local/global, posts, comentários, reações e favoritos.','Publicação persiste; contadores coerentes; reação/favorito isolado por usuário.'],
    ['Conteúdo acadêmico','Grupos, disciplinas, materiais, stories, tags e menções.','Demonstrar apenas os recursos efetivamente validados na versão exibida.'],
    ['Mensagens','Chats, membros, texto, anexos e Socket.IO.','Enviar/receber entre clientes; impedir acesso por não membro; testar reconexão.'],
],[83,205,W-288])
h2('Recorte demonstrável')
p('O fluxo principal sugerido é: entrar com conta de demonstração, consultar perfil, publicar no feed, conectar-se a outro estudante e trocar uma mensagem. Esse recorte oferece uma sequência compreensível do problema até o valor entregue, sem depender de apresentar todas as telas.')
note('Estado de homologação','Os testes locais confirmam comportamentos delimitados. O vídeo foi confirmado por Davi, mas não disponibilizado para análise. Não há registro e2e nesta rodada comprovando o fluxo completo com banco, storage e dispositivos reais. Essa etapa permanece no backlog de aceite.')
evidence('lib/core/router/app_router.dart; serviços e controllers do backend; docs/entrega/sdd-as-built.md; docs/entrega/roteiro-video.md.')

# 5
section('Passo 3','Refinamento por testes e re-especificação','step3')
p('O refinamento transforma uma divergência observada em regra explícita, correção e regressão verificável. Os casos abaixo foram tratados nesta preparação; não são propostas apresentadas como já implementadas.')
table(['ID','ERRO / DIVERGÊNCIA','CONTRATO REFINADO E VERIFICAÇÃO'],[
    ['RE-07','Consentimento aceitava user_id do corpo.','O titular vem de CurrentUser/JWT. Testes HTTP rejeitam ausência de token e ignoram identidade forjada.'],
    ['RE-08','Cache de feed compartilhava reação/favorito entre usuários da mesma instituição.','A chave inclui o usuário. Teste exige chaves distintas para Alice e Bob.'],
    ['RE-09','Prefixo semelhante podia ser encaminhado como rota válida.','Rota deve ser prefixo exato ou subcaminho. Integração exige 404 para /users-evil.'],
    ['RE-10','Notificação interna não exigia credencial de serviço.','X-Internal-Token obrigatório; ausência, token errado ou configuração ausente retornam 401.'],
    ['RE-11','Readiness era estático e alguns healthchecks faltavam/eram protegidos.','Liveness público; readiness consulta quatro serviços e retorna 503 em indisponibilidade.'],
    ['RE-12','OTP podia aparentar envio sem provedor ou após erro externo.','Envio indisponível retorna 503; log de OTP exige opção explícita de desenvolvimento.'],
    ['RE-13','JavaScript compilado coexistia com TypeScript, afetando resolução/cobertura.','Cópias geradas removidas; Jest prioriza TS. Nova execução mede os fontes atuais.'],
],[45,190,W-235])
h2('Ciclo adotado')
p('Reproduzir o comportamento → especificar esperado → implementar o ajuste → executar a regressão → atualizar o As-Built → revisar o diff. Os testes não substituem revisão humana nem justificam alterar um requisito só para acomodar um defeito.')
evidence('backend/test/auth.test.js; domain.test.js; http-integration.test.js; gateway-integration.test.js; notifications.test.js; otp.test.js. Os refinamentos RE-01 a RE-06 permanecem no relatório histórico de 12/10.')

# 6
section('Passo 4','Governança: comprovado e pendente','step4')
p('A governança precisa ser demonstrada por registros, não apenas descrita como intenção. A consulta pública ao GitHub em 25/10/2026 e o histórico local permitem as conclusões abaixo.')
table(['VERIFICAÇÃO','EVIDÊNCIA / CONCLUSÃO'],[
    ['Branches e PRs históricos','O histórico inclui merges, como o PR #11 no commit 5f1b26f. Isso comprova uso de PR, mas não comprova revisão independente ou aprovação qualificada.'],
    ['PRs abertos','Consulta inicial: zero PRs. A entrega foi enviada pelo PR #12; sua integração deve ser conferida antes da tag.'],
    ['Branch principal','Na consulta inicial, master era a padrão, sem proteção. O proprietário configurará a main, conforme orientação de Davi.'],
    ['Release oficial','Nenhuma release existente na consulta. A tag estável ainda não foi publicada.'],
    ['Sprint/board/revisores','Não há evidência suficiente para atribuir datas de sprint, reuniões, issues ou revisão por outro integrante.'],
],[112,W-112])
h2('Critérios de aceitação para integrar a candidata')
p('1. Harness e build aprovados no commit revisado.<br/>2. Configuração Docker e smoke test aprovados em runtime real.<br/>3. Contratos e documentação compatíveis com os fontes.<br/>4. Nenhum segredo ou artefato temporário no conjunto versionado.<br/>5. Limitações conhecidas registradas e fluxos de demonstração homologados.<br/>6. Aprovação humana identificada antes da tag oficial.')
h2('Mecanismos preparados')
p('O workflow de validação executa harness, stack Docker e smoke test. O de publicação exige execução na main, SHA aprovado correspondente, branch protegida e zero PRs abertos. As regras de proteção e o environment de aprovação ainda precisam ser configurados no GitHub.')
note('Responsabilidade','Somente Davi Vieira foi informado como integrante. Revisão independente exige um revisor real; não se presume uma equipe ou aprovação que não esteja documentada.')
evidence('reports/release/github-state.json; .github/workflows/validate-release.yml; publish-release.yml; docs/entrega/checklist-release.md.')

# 7
section('Passo 5 / execução','README final e instalação','step5')
p('O README foi atualizado para concentrar ambiente, variáveis, execução, testes e evidências. Os comandos abaixo partem da raiz do repositório. O ambiente é de demonstração, com sincronização TypeORM em desenvolvimento.')
h2('Pré-requisitos')
p('Containers: Docker com Compose v2.20+ e Python 3.10+ para configuração. Execução local: Flutter 3.38.10, Dart compatível com ^3.10.0, Node 20 como referência de CI/containers e Python 3.10+. Android também requer JDK 17, SDK e emulador/aparelho.')
h2('Configuração e aplicação')
code('python .scripts/init-env.py\ndocker compose --env-file backend/.env up --build -d --wait')
p('O gerador cria backend/.env com segredos aleatórios e preserva arquivo existente. Configurar RESEND_API_KEY/RESEND_FROM para OTP real e S3_PUBLIC_ENDPOINT para um endereço alcançável pelo dispositivo. O código usa Resend; variáveis SMTP não configuram o envio atual.')
p('Frontend: <b>localhost:8080</b>. API: <b>localhost:3000/api/v1</b>. Readiness: <b>/api/v1/health/ready</b>. Socket.IO: porta 3004, namespace /ws.')
h2('Harness e diagnóstico')
code('npm --prefix backend ci --no-audit --no-fund\nflutter pub get --enforce-lockfile\npython .scripts/run-tests.py')
code('docker compose -f compose.test.yaml run --build --rm harness\nnode .scripts/smoke-test.mjs')
p('A primeira linha do segundo bloco é a alternativa de testes em container. O smoke test exige a aplicação já iniciada. Logs e resultados são gravados em reports/release. O harness retorna código diferente de zero quando uma etapa falha.')
note('Resultado observado','A stack Docker foi executada no GitHub Actions: todos os serviços saudáveis, 9/9 smoke checks, 97/97 testes no container e pacote web exportado. Os builds locais também passaram.')

# 8
section('Passo 5 / arquitetura','Arquitetura e fluxo da aplicação','architecture')
story.append(Architecture());space(8)
p('O cliente Flutter usa repositórios e um cliente HTTP para o gateway. Os serviços validam autenticação e regras de domínio. As conexões em tempo real usam diretamente o serviço de mensagens. A persistência de desenvolvimento é um PostgreSQL compartilhado por schemas.')
table(['FLUXO','SEQUÊNCIA EFETIVA'],[
    ['Cadastro','Email institucional → OTP → token temporário → credencial/consentimento → tokens → evento de cadastro → perfil. O evento usa Pub/Sub best-effort.'],
    ['Publicação','Tela → notifier/repositório → API → serviço de posts → banco/storage → resposta → atualização de estado/feed. Cache pode reter dados por até 60 segundos.'],
    ['Mensagem','Cliente autenticado → chat → verificação de membro → persistência → evento message:new para a sala. O fluxo entre dispositivos ainda precisa de homologação.'],
],[80,W-80])
p('<b>Limites arquiteturais:</b> há consultas SQL entre schemas no perfil/exportação; não existe isolamento físico completo de bancos. Objetos MinIO usam política pública de leitura. Isso exige evolução antes de tratar anexos como privados.','small')
evidence('SDD As-Built; inventário de 93 entradas HTTP, 13 arquivos de DTO e 31 entidades. As assinaturas e regras detalhadas permanecem nos documentos técnicos anexos ao repositório.')

# 9
section('Passo 6 / decisões 1-3','ADRs consolidados','step6')
p('Os ADRs são uma consolidação retrospectiva das escolhas observadas. Não são atas de decisões passadas nem comprovam participação ou aprovação de pessoas não registradas.')
for title,context,decision,alternative,tradeoff,proof in [
    ('ADR-001 | Flutter e separação em camadas','A aplicação reúne telas com sessão, rede e entidades compartilhadas.','Organizar core, domain, data e presentation; usar notifiers/Provider.','Concentrar rede e estado diretamente nas telas.','Favorece testes e contratos, mas aumenta arquivos, mocks e sincronização entre camadas. Para um primeiro mobile, essa complexidade precisa ser administrada.','lib/; test/notifiers; test/network; test/widgets.'),
    ('ADR-002 | NestJS por domínio e gateway','Autenticação, perfil, feed e mensagens têm responsabilidades distintas.','Separar serviços e compartilhar JWT/Redis/DTOs em um pacote comum.','Monólito modular.','Separação facilita localizar responsabilidades; aumenta processos, configuração, rede e modos de falha. Um monólito seria mais simples operacionalmente para um MVP pequeno.','backend/package.json e módulos dos serviços.'),
    ('ADR-003 | PostgreSQL e Redis','A solução precisa de persistência relacional, TTL e comunicação de eventos.','Schemas por domínio; Redis para OTP, cache e Pub/Sub.','Banco sem fronteiras ou mensageria durável com confirmação.','O isolamento por schema é parcial e há consultas cruzadas. Pub/Sub não garante entrega durável; cadastro/perfil precisam de testes integrados e recuperação de falhas.','shared/database; shared/redis; init-db.sql; events.subscriber.ts.'),
]:
    h2(title);p(f'<b>Contexto:</b> {context}<br/><b>Decisão:</b> {decision}<br/><b>Alternativa:</b> {alternative}<br/><b>Defesa e custo:</b> {tradeoff}');evidence(proof)

# 10
section('Passo 6 / decisões 4-6','Defesa das decisões de entrega','adr-more')
for title,content,proof in [
    ('ADR-004 | JWT e renovação limitada','<b>Contexto:</b> tokens expiram e requisições podem receber 401.<br/><b>Decisão:</b> backend verifica o token; cliente restaura estado a partir de claims e faz no máximo uma repetição após refresh.<br/><b>Alternativa:</b> renovar indefinidamente ou pedir login em toda expiração.<br/><b>Defesa:</b> evita ciclos e preserva erros de credenciais. A inspeção local de claims não substitui autorização criptográfica no servidor.','ApiClient, AuthNotifier, estratégia JWT e testes de sessão.'),
    ('ADR-005 | Compose e storage compatível com S3','<b>Contexto:</b> reproduzir aplicação, banco, cache e arquivos.<br/><b>Decisão:</b> Compose com imagens-base por digest; MinIO construído de commit oficial e checksum fixos.<br/><b>Alternativa:</b> instalação manual ou serviços gerenciados.<br/><b>Defesa:</b> descreve entradas do build e reduz variação. O primeiro build é pesado; execução aprovada no CI 40236431191. Objetos públicos e synchronize limitam uso com dados reais.','compose.yaml; Dockerfiles; deploy/images.lock.json; storage/Dockerfile.'),
    ('ADR-006 | Harness único e evidência por execução','<b>Contexto:</b> testes isolados e resultados históricos dificultam defender a versão entregue.<br/><b>Decisão:</b> um comando compila backend, roda Jest/Flutter e gera JSON, JUnit, LCOV e hashes dos fontes.<br/><b>Alternativa:</b> comandos manuais sem consolidação.<br/><b>Defesa:</b> torna o procedimento repetível e auditável. A aprovação mede os casos executados; cobertura e e2e continuam critérios separados.','run-tests.py; release-report.py; reports/release/run.json.'),
]: h2(title);p(content);evidence(proof)
note('Síntese para a defesa oral','Justifique cada escolha pelo problema resolvido, explicite o custo e a alternativa descartada, e mostre a evidência correspondente. Evite apresentar uma tecnologia como superior em qualquer contexto.')

# 11
section('Passo 7','Relato de experiência','step7')
p('Responsável informado: <b>Davi Vieira</b>. Ferramentas utilizadas: <b>Claude e ChatGPT</b>. Não foram informados outros integrantes ou uma divisão de tarefas entre pessoas; por isso, o relato preserva a experiência individual e não inventa dinâmica de grupo.')
p('“A maior dificuldade foi por desenvolver uma aplicação mobile, nunca tinha feito e achei bem mais complexo de se desenvolver.”','quote')
h2('Relato consolidado para revisão do autor')
p('O InteraEdu foi minha primeira experiência de desenvolvimento de uma aplicação mobile. A dificuldade principal foi lidar com uma complexidade maior do que eu esperava. O trabalho exigiu compreender não só as telas, mas também o estado da interface, a sessão, a comunicação com o backend e a configuração necessária para executar o sistema.')
p('Utilizei Claude e ChatGPT durante o projeto. A preparação da entrega evidenciou que uma funcionalidade descrita ou implementada ainda precisa de verificação prática. Testes, contratos e documentação ajudam a transformar uma solução que parece correta em uma solução cujo comportamento pode ser explicado e conferido.')
p('A principal lição técnica é organizar desde o início os critérios de aceitação e as evidências. A principal lição de governança é manter claro o que está implementado, o que foi testado e o que ainda depende de revisão ou homologação. A IA pode ajudar na elaboração e no refinamento, mas a responsabilidade pela versão entregue permanece com o responsável pelo projeto.')
h2('Produtividade e trabalho coletivo')
p('Foram produzidos testes, relatórios e documentação repetível nesta etapa. Não há medição de horas que permita declarar um percentual de produtividade. Também não há registro suficiente para avaliar distribuição de trabalho ou revisão entre pares. Essas lacunas devem permanecer explícitas na defesa.')
note('Validação pessoal','O trecho entre aspas reproduz o relato fornecido por Davi. Os demais parágrafos são uma síntese editorial baseada nesse relato e nos artefatos observados; precisam de leitura e aceite do autor antes da submissão.')

# 12
section('Passo 8','Matriz comparativa das ferramentas de IA','step8')
p('A comparação considera <b>Claude</b> e <b>ChatGPT</b>, as duas ferramentas informadas por Davi. Não foi realizado um experimento controlado com a mesma tarefa, modelos, prompts e tempo. A matriz compara a evidência disponível, sem inventar notas ou superioridade entre produtos.')
table(['CRITÉRIO','CLAUDE','CHATGPT / ASSISTÊNCIA DESTA ETAPA'],[
    ['Uso no projeto','Uso confirmado pelo responsável. Interface/modelo e tarefas específicas não registrados.','Uso confirmado; esta conversa registra inspeção, alterações, testes e documentação.'],
    ['Aderência à especificação','Sem conjunto de prompts/patches para avaliação independente.','Foram comparados contratos e código; diferenças foram incorporadas ao As-Built.'],
    ['Correção e testes','Não há testes atribuíveis exclusivamente à ferramenta.','61 testes backend acrescentados; execução consolidada de 97 casos. Aprovação depende dos testes e da revisão, não da autoria da sugestão.'],
    ['Segurança e limites','Não mensurados nesta documentação.','Correções verificadas de identidade, cache e token interno; limites de Docker, cobertura e release registrados.'],
    ['Produtividade','Sem medição de tempo ou intervenções.','Artefatos produzidos são observáveis; ganho percentual não medido.'],
    ['Limitação da comparação','Ausência de logs impede atribuição detalhada.','Maior disponibilidade de evidência não demonstra superioridade geral sobre Claude.'],
],[90,181,W-271])
h2('Protocolo para uma comparação empírica futura')
p('Aplicar às duas ferramentas o mesmo recorte de código e critério de aceite, em cópias isoladas. Registrar modelo/versão, prompt, tempo, intervenções e patch. Rodar a mesma suíte e avaliar aderência, correção, casos de borda, segurança e clareza. Só então atribuir notas ou concluir sobre ganho de produtividade.')
p('Se o enunciado exigir um benchmark empírico entre ferramentas, esta matriz descritiva não substitui essa execução.','small')

# 13
section('Passo 9','Relatório ético-técnico: quatro pilares','step9')
p('Os quatro pilares adotados organizam os riscos do uso de IA e os controles do projeto. Eles não representam certificação jurídica, auditoria de segurança completa ou aprovação humana já concluída.')
for title,text in [
    ('1. Confiabilidade, alucinação e segurança','<b>Risco:</b> sugestões plausíveis podem divergir do contrato, omitir autorização ou produzir testes que não exercitam o fonte atual.<br/><b>Controle aplicado:</b> inspeção do diff, regressões de identidade/cache, remoção de cópias compiladas e nova execução de testes.<br/><b>Limite:</b> cobertura parcial e integração isolada não garantem ausência de defeitos no produto inteiro.'),
    ('2. Privacidade e confidencialidade','<b>Risco:</b> exposição de .env, tokens, emails, mensagens e dados acadêmicos em prompts ou logs.<br/><b>Controle aplicado:</b> segredos gerados localmente, arquivos de ambiente ignorados, dados sintéticos nos testes e OTP em log somente por opção explícita de desenvolvimento.<br/><b>Pendente:</b> revisão do histórico e da política de anexos, hoje com leitura pública no storage.'),
    ('3. Propriedade intelectual e autoria','<b>Risco:</b> tratar código gerado como automaticamente original ou ignorar licenças de dependências e vendor.<br/><b>Controle aplicado:</b> identificação de Claude/ChatGPT e do responsável; origem fixa do MinIO e licença preservada na imagem.<br/><b>Pendente:</b> auditoria de licenças e decisão do titular sobre a licença do projeto. Não se presume titularidade a partir da geração por IA.'),
    ('4. Homologação humana e responsabilização','<b>Risco:</b> publicar como estável algo sem revisão, inventar aprovação ou apresentar métricas fora de contexto.<br/><b>Controle preparado:</b> checklist, checks de CI, referência ao SHA aprovado e exigência de main protegida na publicação.<br/><b>Pendente:</b> revisão/aceite identificados, configuração real das regras e demonstração funcional. Davi continua responsável pelo conteúdo entregue.'),
]: h2(title);p(text)

# 14
section('Passo 10 / execução','Relatório de testes: 100% pass','step10')
p('Na execução consolidada de <b>25/10/2026, das 12:25:46 às 12:28:30</b> (America/Sao_Paulo), todos os casos coletados passaram. O commit-base é d04d949; alterações testadas são identificadas por hash no manifesto. Esta aprovação não equivale à homologação de uma release publicada.')
table(['SUÍTE','TOTAL','APROVADOS','FALHAS','IGNORADOS'],[['Flutter','36','36','0','0'],['Backend','61','61','0','0'],['Total','97','97','0','0']],[127,94,94,94,W-409])
h2('Etapas automatizadas')
table(['ETAPA','RESULTADO E ESCOPO'],[
    ['Build backend','Sucesso nos seis workspaces: shared, gateway, auth, profile, feed e messaging.'],
    ['Testes backend','6 suítes Jest; unidade e integração HTTP com servidores locais e dependências isoladas.'],
    ['Testes Flutter','Modelos, rede, sessão, notifiers e widgets; sem execução em aparelho real.'],
    ['Build web adicional','Compilação release concluída; cache local de dependências foi isolado após arquivos ausentes no cache global.'],
    ['Compose e CI','Stack saudável, 9/9 smoke checks e 97/97 testes no container. CI: 40236431191.'],
],[115,W-115])
h2('Cobertura não é taxa de aprovação')
story.append(CoverageBars())
p('A taxa de aprovação é <b>100% dos 97 casos executados</b>. A cobertura de linhas é <b>22,00% no Flutter</b> (1.285/5.841) e <b>23,94% no backend</b> (480/2.005). Esses percentuais medem dimensões diferentes e devem ser apresentados juntos.','small')

p('Repetição em Linux: 97/97 aprovados, cobertura Flutter 21,98%. Em Docker: 97/97 aprovados, cobertura Flutter 21,97%. Backend 23,94% em todas. Evidências: reports/release/ci/initial e ci/docker.','small')

# 15
section('Passo 10 / cobertura','Unidades críticas e limites da evidência','coverage')
rows=[]
keys=[('auth-service/src/auth/auth.service.ts','Autenticação'),('auth-service/src/otp/otp.service.ts','OTP'),('gateway/src/proxy/proxy.service.ts','Serviço de proxy'),('gateway/src/proxy/proxy.controller.ts','Controller de proxy'),('shared/src/auth/jwt-auth.guard.ts','Guard JWT'),('shared/src/auth/jwt.strategy.ts','Estratégia JWT'),('profile-service/src/connections/connections.service.ts','Conexões'),('feed-service/src/posts/posts.service.ts','Posts/feed'),('messaging-service/src/chats/chats.service.ts','Chats'),('messaging-service/src/notifications/notifications.controller.ts','Notificações')]
for suffix,label in keys:
    metric=next(v['lines'] for k,v in cov.items() if k.replace('\\','/').endswith(suffix))
    rows.append([label,f"{metric['covered']}/{metric['total']}",f"{metric['pct']:.2f}%".replace('.',',')])
table(['UNIDADE BACKEND','LINHAS COBERTAS','COBERTURA'],rows,[240,135,W-375])
p('No Flutter, o relatório detalha também ApiClient (52,21%), AuthNotifier (66,15%) e FeedNotifier (62,96%). Os números completos estão nos arquivos LCOV e no resumo por arquivo.','small')
h2('O que foi realmente integrado')
p('Os testes HTTP iniciam aplicações Nest reais, exercitam validação de DTO, autenticação JWT e o proxy para um servidor HTTP local. Repositórios e Redis são isolados por mocks em testes de domínio. Isso permite verificar contratos sem depender da infraestrutura externa.')
h2('O que ainda não foi homologado')
p('A stack com PostgreSQL, Redis e MinIO iniciou e passou no smoke test. Ainda falta homologar envio real via Resend, criação de perfil por evento, uploads e conversas entre dispositivos em um fluxo completo. A medição backend exclui bootstrap, módulos de DI, entidades, DTOs e interfaces; inclui serviços/controllers sem testes, reduzindo a chance de ocultar lacunas.')
evidence('reports/release/relatorio.md; summary.json; junit.xml; backend-tests.json; flutter-events.jsonl; backend-coverage/coverage-summary.json; arquivos LCOV.')

# 16
section('Checklist final','Itens obrigatórios e situação real','checklist')
table(['ITEM','SITUAÇÃO','EVIDÊNCIA / PRÓXIMO PASSO'],[
    ['Auditoria e backlog','Preparado','Auditoria no Passo 1; backlog de fechamento priorizado.'],
    ['Solução funcional','Parcial','Implementação existente; homologar o fluxo completo e registrar resultado.'],
    ['Testes e re-especificação','Verificado localmente','97 casos aprovados; contratos refinados e regressões documentados.'],
    ['Governança e sprints','Parcial','PRs históricos e consulta atual; faltam regras, revisão e registros de sprint.'],
    ['README e arquitetura','Preparado','Guia, diagrama, variáveis e comandos atualizados.'],
    ['ADRs','Preparado','Seis decisões consolidadas com alternativas, custos e evidências.'],
    ['Relato de experiência','Preparado','Davi Vieira; síntese pessoal sujeita à revisão do autor.'],
    ['Comparativo de IA','Descritivo','Matriz Claude/ChatGPT; benchmark controlado não realizado.'],
    ['Ética: quatro pilares','Preparado','Riscos, controles e lacunas identificados.'],
    ['Relatório/PDF e cobertura','Verificado localmente','Resultados reais, LCOV/JUnit/JSON e este relatório.'],
    ['main protegida e release','Pendente','Migrar/consolidar master, proteger main, aprovar SHA e publicar tag.'],
    ['Docker reproduzível','Verificado no CI','Stack, smoke test, harness e exportação web aprovados.'],
    ['Vídeo de 3-5 minutos','Gravado','Confirmado por Davi; envio separado pelo responsável.'],
],[133,105,W-238])
note('Condição para declarar a entrega concluída','Os itens preparados e os testes locais estão disponíveis. A conclusão integral exige fechar as pendências de execução, aprovação e evidência, especialmente release, proteção da main pelo proprietário e aceite funcional. O vídeo será enviado separadamente. Este PDF não converte pendências em resultados obtidos.')

# 17
section('Apêndice A','Cronograma da sprint e critérios de saída','sprint')
p('O quadro é um <b>plano proposto de fechamento</b>, não um calendário retrospectivo de trabalho realizado. D1 a D5 são sessões/dias relativos a agendar por Davi; a duração deve ser ajustada ao resultado da homologação.')
table(['DIA','ATIVIDADE','CRITÉRIO DE SAÍDA'],[
    ['D1','Revisar auditoria, backlog e As-Built; instalar/validar Docker.','Escopo e limitações aceitos; ambiente inicia sem falhas de healthcheck.'],
    ['D2','Executar smoke e fluxos de cadastro, perfil, post, conexão, upload e conversa.','Esperado/obtido registrado; erros reproduzíveis viram issues e testes.'],
    ['D3','Corrigir falhas e reexecutar harness; revisar ADRs, IA e ética.','Checks aprovados na versão candidata e documentação alinhada.'],
    ['D4','Revisar PR/commit, consolidar main, configurar proteção e publicar release.','SHA aprovado, regras ativas, zero PRs pendentes e URL da release.'],
    ['D5','Enviar vídeo separadamente e conferir pacote final.','Vídeo de 3-5 min, PDF revisado, links acessíveis e evidências do mesmo commit.'],
],[45,230,W-275])
h2('Registros históricos efetivamente disponíveis')
p('<b>17/10/2026:</b> relatório de 36 testes Flutter aprovados; backend então bloqueado pela ausência de Jest/testes.<br/><b>25/10/2026:</b> novo harness, 61 testes backend, 97 casos aprovados no total, build web/backend, stack Docker, 9 smoke checks e harness em container aprovados.<br/><b>GitHub na consulta de 25/10:</b> consulta inicial sem proteção/release; PR #12 criado nesta etapa e CI aprovado.')
h2('Como comprovar a sprint')
p('Para cada item, registrar responsável, critério de aceite, issue, branch/PR, decisão de revisão e evidência. O cronograma proposto passa a ser histórico apenas quando essas ações ocorrerem e forem registradas. Não criar atas, issues concluídas ou aprovações retroativas fictícias.')

# 18
section('Apêndice B','Guia de evidências e pacote de submissão','evidence')
table(['ID','ARTEFATO','FINALIDADE'],[
    ['E01','README.md','Instalação, execução e visão de entrega.'],
    ['E02','docs/entrega/sdd-as-built.md','Arquitetura e limitações efetivas.'],
    ['E03','contratos-as-built.md / modelos-as-built.md','Rotas, DTOs e entidades extraídos dos fontes.'],
    ['E04','reports/release/run.json / source-sha256.json','Data, comandos, códigos de saída e fontes testados.'],
    ['E05','summary.json / junit.xml / logs de teste','Contagem de casos e resultado verificável.'],
    ['E06','flutter-lcov.info / backend-coverage/','Cobertura geral e por unidade.'],
    ['E07','hygiene.json / artifact-verification.json','Scan de padrões e conferência dos artefatos.'],
    ['E08','github-state.json / compose-validation.json','Estado público consultado e validação de configuração.'],
    ['E09','deploy/images.lock.json','Digests das imagens-base; não prova execução.'],
    ['E10','checklist-release.md / roteiro-video.md','Aceite e roteiro para completar a demonstração.'],
],[35,258,W-293])
p('Os nomes abreviados de E03/E10 ficam em docs/entrega; E05-E08 ficam em reports/release. Anexar os arquivos digitais ao repositório/release mantém os detalhes auditáveis sem inserir milhares de linhas de log no PDF.','small')
h2('Itens ainda a anexar')
p('URL da release e SHA final; evidência de proteção da main; checks de CI do mesmo commit; revisão humana identificada; aceite dos fluxos homologados. Docker/smoke já registrado; vídeo será enviado separadamente. Na apresentação, mostrar resultados ao vivo ou identificar claramente um corte/registro anterior.')
h2('Referências verificáveis')
p('<link href="https://github.com/alencarrgabriel/intera_edu" color="#176449">Repositório InteraEdu: github.com/alencarrgabriel/intera_edu</link><br/><link href="https://github.com/minio/minio/releases/tag/RELEASE.2025-10-15T17-29-55Z" color="#176449">MinIO: revisão oficial usada pelo Dockerfile de storage</link>','small')
p('As referências de código e resultados correspondem à candidata local identificada nos manifests. Novos commits, testes ou homologações exigem atualizar as evidências e, quando necessário, regenerar o PDF.','small')

pdf = OUT / 'InteraEdu_Entrega_2_Relatorio_Final.pdf'
doc=Report(str(pdf),pagesize=A4,rightMargin=46,leftMargin=46,topMargin=54,bottomMargin=52,
           title='InteraEdu - Entrega 2: da fundação ao produto defendido',author='Davi Vieira',
           subject='Relatório técnico, testes, ADRs, ética e evidências da candidata à entrega')
doc.build(story,onFirstPage=page_frame,onLaterPages=page_frame)
print(pdf)
