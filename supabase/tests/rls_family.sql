-- RLS — responsável.
-- Invariante do projeto: o responsável permanece SOMENTE LEITURA dos estudantes
-- vinculados. Aqui isso é asserção, não comentário.
-- Cobre também a revogação por vínculo escolar e por status do link, que antes
-- de 0008 não cortava o acesso.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(13);

\ir helpers/m0_fixture.psql

SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20');
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------ leitura
SELECT is((SELECT count(*)::int FROM public.students), 1,
  'responsável vê apenas o estudante vinculado');
SELECT is((SELECT min(edugame_id) FROM public.students), 'M0-A-001'::text,
  'responsável vê o estudante correto');
SELECT is((SELECT count(*)::int FROM public.classes), 1,
  'responsável vê a turma do estudante vinculado');
SELECT is((SELECT count(*)::int FROM public.enrollments), 1,
  'responsável vê a matrícula do estudante vinculado');
SELECT is((SELECT count(*)::int FROM public.guardian_student_links), 1,
  'responsável vê apenas o próprio vínculo');
SELECT is((SELECT count(*)::int FROM public.schools), 1,
  'responsável vê apenas a escola do vínculo');

-- ---------------------------------------------------------------- revogação
RESET ROLE;
UPDATE public.school_memberships SET status = 'inactive'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20';
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 0,
  'responsável com vínculo escolar revogado perde o acesso');

RESET ROLE;
UPDATE public.school_memberships SET status = 'active'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20';
UPDATE public.guardian_student_links SET status = 'revoked'
 WHERE guardian_user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20';
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 0,
  'link de responsável revogado corta o acesso ao estudante');

RESET ROLE;
UPDATE public.guardian_student_links SET status = 'active'
 WHERE guardian_user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20';
SET LOCAL ROLE authenticated;

-- ------------------------------------------------- somente leitura, de fato
SELECT throws_ok(
  $$UPDATE public.students SET display_name = 'apelido'
     WHERE id = '10000000-0000-0000-0000-000000000011'$$,
  '42501', NULL, 'responsável não altera o registro do estudante');

SELECT throws_ok(
  $$UPDATE public.enrollments SET status = 'inactive'$$,
  '42501', NULL, 'responsável não altera matrícula');

SELECT throws_ok(
  $$UPDATE public.guardian_student_links SET is_primary = true$$,
  '42501', NULL, 'responsável não edita o próprio vínculo');

SELECT throws_ok(
  $$INSERT INTO public.guardian_student_links (guardian_user_id, student_id, school_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20',
            '10000000-0000-0000-0000-000000000012',
            '10000000-0000-0000-0000-000000000001')$$,
  '42501', NULL, 'responsável não se vincula a outro estudante');

SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type) VALUES ('forjado', 'system')$$,
  '42501', NULL, 'responsável não insere auditoria');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
