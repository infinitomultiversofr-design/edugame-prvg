-- RLS — estudante.
-- Cobre leitura (o que o aluno vê) E escrita (o que ele não consegue fazer).
-- A versão anterior só contava linhas visíveis: um aluno capaz de alterar a
-- própria matrícula passaria despercebido.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(17);

\ir helpers/m0_fixture.psql

SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01');
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------ leitura
SELECT is((SELECT count(*)::int FROM public.students), 1,
  'aluno vê apenas o próprio registro de estudante');
SELECT is((SELECT min(edugame_id) FROM public.students), 'M0-A-001'::text,
  'aluno vê o próprio edugame_id');
SELECT is((SELECT count(*)::int FROM public.students
            WHERE id = '10000000-0000-0000-0000-000000000012'), 0,
  'aluno não vê colega da mesma turma');
SELECT is((SELECT count(*)::int FROM public.classes), 1,
  'aluno vê apenas a própria turma');
SELECT is((SELECT count(*)::int FROM public.enrollments), 1,
  'aluno vê apenas a própria matrícula');
SELECT is((SELECT count(*)::int FROM public.schools), 1,
  'aluno vê apenas a própria escola');
SELECT is((SELECT count(*)::int FROM public.teacher_assignments), 0,
  'aluno não vê atribuições docentes');
SELECT is((SELECT count(*)::int FROM public.user_profiles), 1,
  'aluno vê apenas o próprio perfil');
SELECT is((SELECT count(*)::int FROM public.audit_logs), 0,
  'aluno não lê auditoria');

-- ------------------------------------------------------------------ escrita
-- Invariante: o navegador nunca é autoridade sobre matrícula, vínculo,
-- identidade ou auditoria.
SELECT throws_ok(
  $$UPDATE public.students SET display_name = 'hack'
     WHERE id = '10000000-0000-0000-0000-000000000011'$$,
  '42501', NULL, 'aluno não altera o próprio registro de estudante');

SELECT throws_ok(
  $$UPDATE public.students SET school_id = '20000000-0000-0000-0000-000000000001'$$,
  '42501', NULL, 'aluno não se transfere de escola');

SELECT throws_ok(
  $$INSERT INTO public.enrollments (student_id, school_id, academic_year_id, class_id)
    VALUES ('10000000-0000-0000-0000-000000000011',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000004')$$,
  '42501', NULL, 'aluno não cria matrícula em outra turma');

SELECT throws_ok(
  $$INSERT INTO public.school_memberships (user_id, school_id, role)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01',
            '10000000-0000-0000-0000-000000000001', 'director')$$,
  '42501', NULL, 'aluno não se promove a director');

SELECT throws_ok(
  $$INSERT INTO public.guardian_student_links (guardian_user_id, student_id, school_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01',
            '10000000-0000-0000-0000-000000000012',
            '10000000-0000-0000-0000-000000000001')$$,
  '42501', NULL, 'aluno não cria vínculo de responsável sobre colega');

SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type) VALUES ('forjado', 'system')$$,
  '42501', NULL, 'aluno não insere registro de auditoria');

SELECT throws_ok(
  $$UPDATE public.schools SET name = 'renomeada'$$,
  '42501', NULL, 'aluno não altera a escola');

SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
            '10000000-0000-0000-0000-000000000001', true)$$,
  '42501', NULL, 'aluno não liga feature flag para a escola');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
