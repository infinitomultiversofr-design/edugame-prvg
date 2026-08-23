-- RLS — professor.
-- Além da visibilidade, cobre a revogação: suspender o vínculo escolar ou
-- encerrar a atribuição docente precisa cortar o acesso aos dados do aluno.
-- Antes de 0008 o professor suspenso continuava vendo os 2 estudantes da turma.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(16);

\ir helpers/m0_fixture.psql

SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10');
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------ leitura
SELECT is((SELECT count(*)::int FROM public.students), 2,
  'professor vê os estudantes da turma atribuída');
SELECT is((SELECT count(*)::int FROM public.students
            WHERE school_id = '20000000-0000-0000-0000-000000000001'), 0,
  'professor não vê estudante de outra escola');
SELECT is((SELECT count(*)::int FROM public.classes), 1,
  'professor vê apenas a turma atribuída');
SELECT is((SELECT count(*)::int FROM public.teacher_assignments), 1,
  'professor vê apenas a própria atribuição');
SELECT is((SELECT count(*)::int FROM public.enrollments), 2,
  'professor vê as matrículas da turma atribuída');
SELECT is((SELECT count(*)::int FROM public.schools), 1,
  'professor vê apenas a própria escola');

-- -------------------------------------------------- revogação por membership
RESET ROLE;
UPDATE public.school_memberships SET status = 'suspended'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 0,
  'professor com vínculo suspenso perde acesso aos estudantes');
SELECT is((SELECT count(*)::int FROM public.classes), 0,
  'professor com vínculo suspenso perde acesso à turma');
SELECT is((SELECT count(*)::int FROM public.enrollments), 0,
  'professor com vínculo suspenso perde acesso às matrículas');

RESET ROLE;
UPDATE public.school_memberships SET status = 'active'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 2,
  'reativar o vínculo devolve o acesso');

-- --------------------------------------------- revogação por fim de atribuição
RESET ROLE;
UPDATE public.teacher_assignments SET status = 'inactive', ended_at = now()
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 0,
  'atribuição encerrada corta o acesso aos estudantes');
SELECT is((SELECT count(*)::int FROM public.classes), 0,
  'atribuição encerrada corta o acesso à turma');

RESET ROLE;
UPDATE public.teacher_assignments SET status = 'active', ended_at = NULL
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------ escrita
SELECT throws_ok(
  $$UPDATE public.students SET display_name = 'nota 10'
     WHERE id = '10000000-0000-0000-0000-000000000011'$$,
  '42501', NULL, 'professor não altera registro de estudante');

SELECT throws_ok(
  $$INSERT INTO public.enrollments (student_id, school_id, academic_year_id, class_id)
    VALUES ('20000000-0000-0000-0000-000000000011',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000003')$$,
  '42501', NULL, 'professor não matricula estudante');

SELECT throws_ok(
  $$INSERT INTO public.school_memberships (user_id, school_id, role)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10',
            '10000000-0000-0000-0000-000000000001', 'admin')$$,
  '42501', NULL, 'professor não altera os próprios papéis');

-- Professor não está em can_manage_flags: rollout é decisão de gestão.
SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, class_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'class',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000003', true)$$,
  '42501', NULL, 'professor não liga feature flag para a própria turma');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
