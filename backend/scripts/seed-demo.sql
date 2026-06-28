-- ──────────────────────────────────────────────────────────────────────
-- Seed de dados de demonstração — InteraEdu
-- Senha compartilhada para todos os usuários demo: Demo@1234
--   Hash bcrypt (cost 12) abaixo. Para gerar outro:
--     docker exec interaedu-auth-service node -e \
--       "console.log(require('bcrypt').hashSync('NovaSenha', 12))"
-- ──────────────────────────────────────────────────────────────────────

BEGIN;

-- IDs fixos para previsibilidade nas demos
-- Já existentes:
--   joao@ufmg.br   = 937f0f0d-0a85-440b-8892-931fdd87964a
--   maria@usp.br   = f5056024-2bdb-4e00-8116-4c71d48c5a87

-- ── Auth credentials (senha = Demo@1234) ──────────────────────────────
INSERT INTO auth.user_credentials (id, email, password_hash, institution_id, status)
VALUES
  ('937f0f0d-0a85-440b-8892-931fdd87964a', 'joao@ufmg.br',       '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'active'),
  ('f5056024-2bdb-4e00-8116-4c71d48c5a87', 'maria@usp.br',       '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', '79e44efb-e085-4967-b858-89154ce949aa', 'active'),
  ('aaaa0001-1111-4111-8111-111111111111', 'ana@aluno.ufmg.br',   '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'active'),
  ('aaaa0002-2222-4222-8222-222222222222', 'pedro@aluno.ufmg.br', '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'active'),
  ('aaaa0003-3333-4333-8333-333333333333', 'julia@ufmg.br',       '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'active'),
  ('bbbb0001-1111-4111-8111-111111111111', 'carla@usp.br',        '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', '79e44efb-e085-4967-b858-89154ce949aa', 'active'),
  ('bbbb0002-2222-4222-8222-222222222222', 'lucas@alumni.usp.br', '$2b$12$W7CJJU4s7ZytwRapfRyff.ZblM3Gg8x0JloZrUMi4wIUjHQnPM7iS', '79e44efb-e085-4967-b858-89154ce949aa', 'active')
ON CONFLICT (email) DO NOTHING;

-- ── Profile data ──────────────────────────────────────────────────────
-- Preenche perfis dos usuários demo + atualiza os existentes (joao/maria)
INSERT INTO profile.users (id, institution_id, email, full_name, bio, course, period, privacy_level, avatar_url, created_at, updated_at)
VALUES
  ('937f0f0d-0a85-440b-8892-931fdd87964a', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'joao@ufmg.br',
   'João Oliveira', 'Aluno de CC · UFMG. Backend (Go, NestJS) e curioso por sistemas distribuídos.',
   'Ciência da Computação', 3, 'public', 'https://i.pravatar.cc/300?img=33',
   NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),

  ('f5056024-2bdb-4e00-8116-4c71d48c5a87', '79e44efb-e085-4967-b858-89154ce949aa', 'maria@usp.br',
   'Maria Silva', 'Biotecnologia · USP. Bioinformática e visualização de dados genômicos.',
   'Biotecnologia', 5, 'public', 'https://i.pravatar.cc/300?img=44',
   NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),

  ('aaaa0001-1111-4111-8111-111111111111', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'ana@aluno.ufmg.br',
   'Ana Carolina Silva',
   'Estudante de Ciência da Computação, interessada em ML aplicado à saúde. Procurando grupos de estudo entre instituições.',
   'Ciência da Computação', 5, 'public',
   'https://i.pravatar.cc/300?img=47',
   NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),

  ('aaaa0002-2222-4222-8222-222222222222', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'pedro@aluno.ufmg.br',
   'Pedro Henrique Almeida',
   'Engenharia Elétrica · LACE (Laboratório de Controle e Automação). Aberto a colaborações em robótica.',
   'Engenharia Elétrica', 3, 'public',
   'https://i.pravatar.cc/300?img=12',
   NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

  ('aaaa0003-3333-4333-8333-333333333333', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'julia@ufmg.br',
   'Profa. Júlia Fernandes',
   'Professora associada do ICEx. Orientação em métodos numéricos e sistemas dinâmicos. Procuro alunos para iniciação científica.',
   'Matemática (Docente)', NULL, 'public',
   'https://i.pravatar.cc/300?img=49',
   NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

  ('bbbb0001-1111-4111-8111-111111111111', '79e44efb-e085-4967-b858-89154ce949aa', 'carla@usp.br',
   'Carla Mendes Tavares',
   'Biotecnologia — interesse em biologia computacional e descoberta de fármacos. Buscando parceiros em análise de dados.',
   'Biotecnologia', 7, 'public',
   'https://i.pravatar.cc/300?img=24',
   NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

  ('bbbb0002-2222-4222-8222-222222222222', '79e44efb-e085-4967-b858-89154ce949aa', 'lucas@alumni.usp.br',
   'Lucas Oliveira Barros',
   'Mestrando em Física Computacional. Métodos Monte Carlo e física estatística aplicada.',
   'Física', 4, 'public',
   'https://i.pravatar.cc/300?img=15',
   NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  bio = EXCLUDED.bio,
  course = EXCLUDED.course,
  period = EXCLUDED.period,
  privacy_level = EXCLUDED.privacy_level,
  avatar_url = EXCLUDED.avatar_url;

-- ── Skills (catálogo base) ────────────────────────────────────────────
INSERT INTO profile.skills (id, name, slug, category) VALUES
  ('1a02556a-cb5f-4d5d-9c8b-dafd1c6bb0b4', 'Python',          'python',          'programming'),
  ('9926f0f4-2723-46ff-b4a6-82b5f3fc40c1', 'Machine Learning', 'machine-learning', 'data-science'),
  ('cd65c6c3-0c5a-49e1-8d35-d1e1b85012af', 'Data Analysis',   'data-analysis',   'data-science'),
  ('cb17375a-8814-4942-8de2-7adcf0f73e63', 'UI/UX',           'ui-ux',           'design'),
  ('02a16a75-17f9-40f8-af67-e2d916d5f4ec', 'React',           'react',           'programming')
ON CONFLICT DO NOTHING;

-- ── Skills vinculadas a alguns usuários ───────────────────────────────
-- Ana → Python, ML, Data Analysis
INSERT INTO profile.user_skills (user_id, skill_id) VALUES
  ('aaaa0001-1111-4111-8111-111111111111', '1a02556a-cb5f-4d5d-9c8b-dafd1c6bb0b4'),
  ('aaaa0001-1111-4111-8111-111111111111', '9926f0f4-2723-46ff-b4a6-82b5f3fc40c1'),
  ('aaaa0001-1111-4111-8111-111111111111', 'cd65c6c3-0c5a-49e1-8d35-d1e1b85012af'),
-- Carla → Python, Data Analysis
  ('bbbb0001-1111-4111-8111-111111111111', '1a02556a-cb5f-4d5d-9c8b-dafd1c6bb0b4'),
  ('bbbb0001-1111-4111-8111-111111111111', 'cd65c6c3-0c5a-49e1-8d35-d1e1b85012af'),
-- Maria → ML, UI/UX
  ('f5056024-2bdb-4e00-8116-4c71d48c5a87', '9926f0f4-2723-46ff-b4a6-82b5f3fc40c1'),
  ('f5056024-2bdb-4e00-8116-4c71d48c5a87', 'cb17375a-8814-4942-8de2-7adcf0f73e63'),
-- João → React, Python
  ('937f0f0d-0a85-440b-8892-931fdd87964a', '02a16a75-17f9-40f8-af67-e2d916d5f4ec'),
  ('937f0f0d-0a85-440b-8892-931fdd87964a', '1a02556a-cb5f-4d5d-9c8b-dafd1c6bb0b4'),
-- Lucas → ML, Data
  ('bbbb0002-2222-4222-8222-222222222222', '9926f0f4-2723-46ff-b4a6-82b5f3fc40c1'),
  ('bbbb0002-2222-4222-8222-222222222222', 'cd65c6c3-0c5a-49e1-8d35-d1e1b85012af')
ON CONFLICT DO NOTHING;

-- ── Conexões aceitas (intra e inter instituicional) ───────────────────
-- Limpa apenas as conexões dos usuários demo pra idempotência
DELETE FROM profile.connections WHERE requester_id IN (
  '937f0f0d-0a85-440b-8892-931fdd87964a','f5056024-2bdb-4e00-8116-4c71d48c5a87',
  'aaaa0001-1111-4111-8111-111111111111','aaaa0002-2222-4222-8222-222222222222',
  'aaaa0003-3333-4333-8333-333333333333',
  'bbbb0001-1111-4111-8111-111111111111','bbbb0002-2222-4222-8222-222222222222'
) OR addressee_id IN (
  '937f0f0d-0a85-440b-8892-931fdd87964a','f5056024-2bdb-4e00-8116-4c71d48c5a87',
  'aaaa0001-1111-4111-8111-111111111111','aaaa0002-2222-4222-8222-222222222222',
  'aaaa0003-3333-4333-8333-333333333333',
  'bbbb0001-1111-4111-8111-111111111111','bbbb0002-2222-4222-8222-222222222222'
);

INSERT INTO profile.connections (id, requester_id, addressee_id, status, requested_at, responded_at) VALUES
  -- João conectado com Ana (UFMG↔UFMG), Carla (UFMG↔USP) e Pedro (UFMG↔UFMG)
  (gen_random_uuid(), '937f0f0d-0a85-440b-8892-931fdd87964a', 'aaaa0001-1111-4111-8111-111111111111', 'accepted', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  (gen_random_uuid(), '937f0f0d-0a85-440b-8892-931fdd87964a', 'bbbb0001-1111-4111-8111-111111111111', 'accepted', NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),
  (gen_random_uuid(), 'aaaa0002-2222-4222-8222-222222222222', '937f0f0d-0a85-440b-8892-931fdd87964a', 'accepted', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  -- Maria conectada com Lucas (USP↔USP) e Ana (USP↔UFMG)
  (gen_random_uuid(), 'f5056024-2bdb-4e00-8116-4c71d48c5a87', 'bbbb0002-2222-4222-8222-222222222222', 'accepted', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (gen_random_uuid(), 'aaaa0001-1111-4111-8111-111111111111', 'f5056024-2bdb-4e00-8116-4c71d48c5a87', 'accepted', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
  -- Solicitações pendentes para o João — ideal para demonstrar a aba
  (gen_random_uuid(), 'bbbb0002-2222-4222-8222-222222222222', '937f0f0d-0a85-440b-8892-931fdd87964a', 'pending', NOW() - INTERVAL '6 hours', NULL),
  (gen_random_uuid(), 'aaaa0003-3333-4333-8333-333333333333', '937f0f0d-0a85-440b-8892-931fdd87964a', 'pending', NOW() - INTERVAL '2 hours', NULL);

-- ── Posts no feed ─────────────────────────────────────────────────────
-- Limpa apenas posts dos demo
DELETE FROM feed.posts WHERE author_id IN (
  '937f0f0d-0a85-440b-8892-931fdd87964a','f5056024-2bdb-4e00-8116-4c71d48c5a87',
  'aaaa0001-1111-4111-8111-111111111111','aaaa0002-2222-4222-8222-222222222222',
  'aaaa0003-3333-4333-8333-333333333333',
  'bbbb0001-1111-4111-8111-111111111111','bbbb0002-2222-4222-8222-222222222222'
);

INSERT INTO feed.posts (id, author_id, institution_id, content, scope, media_urls, reaction_count, comment_count, created_at, updated_at) VALUES
  (gen_random_uuid(), 'aaaa0003-3333-4333-8333-333333333333', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Aberta a iniciação científica em métodos numéricos aplicados a sistemas biológicos. Procuro estudantes de CC ou Matemática a partir do 4° período. Bolsas FAPEMIG disponíveis.',
   'global', '{}', 0, 0, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),

  (gen_random_uuid(), 'bbbb0001-1111-4111-8111-111111111111', '79e44efb-e085-4967-b858-89154ce949aa',
   'Alguém da CC interessado em colaborar num pipeline de análise de expressão gênica? Tenho os dados, falta a parte de visualização interativa. Pago em café e coautoria.',
   'global', '{}', 0, 0, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

  (gen_random_uuid(), '937f0f0d-0a85-440b-8892-931fdd87964a', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Grupo de estudos de Sistemas Distribuídos abrindo vagas. Acabamos de terminar MIT 6.824 (lab 1) e vamos atacar o Raft no próximo sprint. Quem se anima?',
   'local', '{}', 0, 0, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

  (gen_random_uuid(), 'aaaa0001-1111-4111-8111-111111111111', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Recém saída do workshop de PyTorch da SBC. Compartilho meus slides com quem quiser — DM aí.',
   'local', '{}', 0, 0, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

  (gen_random_uuid(), 'aaaa0002-2222-4222-8222-222222222222', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Concluímos o protótipo do braço robótico modular. Foto em breve. Obrigado à equipe do LACE!',
   'local', '{}', 0, 0, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

  (gen_random_uuid(), 'bbbb0002-2222-4222-8222-222222222222', '79e44efb-e085-4967-b858-89154ce949aa',
   'Quem mais aqui usa Julia para Monte Carlo? Estou apanhando com paralelismo distribuído entre processos.',
   'global', '{}', 0, 0, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

  (gen_random_uuid(), 'f5056024-2bdb-4e00-8116-4c71d48c5a87', '79e44efb-e085-4967-b858-89154ce949aa',
   'Encontrei um dataset gigante de mutações do câncer de mama — vou postar uma análise inicial em D3.js essa semana. Aceito sugestões de paletas acessíveis!',
   'global', '{}', 0, 0, NOW() - INTERVAL '7 hours', NOW() - INTERVAL '7 hours'),

  (gen_random_uuid(), '937f0f0d-0a85-440b-8892-931fdd87964a', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Acabei de descobrir o ``EXPLAIN ANALYZE`` no Postgres. Mudou minha vida. Por que isso não estava na ementa de Banco de Dados?',
   'local', '{}', 0, 0, NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),

  (gen_random_uuid(), 'aaaa0001-1111-4111-8111-111111111111', 'f2f1bd56-0bdd-406f-acc3-d0d7c21a027a',
   'Iniciei um repositório com problemas de DP resolvidos em Python — focado em entrevistas técnicas. Issues abertas pra quem quiser contribuir.',
   'local', '{}', 0, 0, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours');

COMMIT;

-- Resumo final
SELECT 'users' AS tabela, COUNT(*) AS qtd FROM profile.users
UNION ALL SELECT 'connections', COUNT(*) FROM profile.connections
UNION ALL SELECT 'posts', COUNT(*) FROM feed.posts
UNION ALL SELECT 'skills_atribuidas', COUNT(*) FROM profile.user_skills;
