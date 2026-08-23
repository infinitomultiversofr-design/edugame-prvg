-- RLS — gestão (coordenação).
-- Gestão enxerga a própria escola inteira e opera feature flags, mas continua
-- sem escrever no domínio escolar pelo cliente: isso é server-authoritative.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(15);

\ir helpers/m0_fixture.psql

SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa30');
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------ leitura
SELECT is((SELECT count(*)::int FROM public.students), 2,
  'coordenação vê os estudantes da escola A');
SELECT is((SELECT count(*)::int FROM public.students
            WHERE school_id = '20000000-0000-0000-0000-000000000001'), 0,
  'coordenação não vê estudantes da escola B');
SELECT is((SELECT count(*)::int FROM public.schools), 1,
  'coordenação vê apenas a própria escola');
SELECT is((SELECT count(*)::int FROM public.classes), 2,
  'coordenação vê as turmas da escola A');
SELECT is((SELECT count(*)::int FROM public.enrollments), 2,
  'coordenação vê as matrículas da escola A');
SELECT is((SELECT count(*)::int FROM public.school_memberships), 5,
  'coordenação vê os vínculos da escola A e nenhum da B');
SELECT is((SELECT count(*)::int FROM public.teacher_assignments), 1,
  'coordenação vê as atribuições docentes da escola A');
SELECT is((SELECT count(*)::int FROM public.guardian_student_links), 1,
  'coordenação vê os vínculos de responsável da escola A');

-- ------------------------------------------------------- rollout autorizado
SELECT lives_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, class_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'class',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000003', true)$$,
  'coordenação liga feature flag para turma da própria escola');

SELECT ok(
  (SELECT count(*) FROM public.audit_logs
    WHERE action = 'feature_flag_override_created') > 0,
  'coordenação enxerga o registro de auditoria da própria mudança');

-- ------------------------------------------------------- rollout não autorizado
SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'global', true)$$,
  '42501', NULL, 'coordenação não cria override global');

SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
            '20000000-0000-0000-0000-000000000001', true)$$,
  '42501', NULL, 'coordenação não cria override para outra escola');

-- Antes de 0008 isto era aceito e plantava o UUID de um usuário de outra
-- escola nos dados da escola A.
SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, user_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'user',
            '10000000-0000-0000-0000-000000000001',
            'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb10', true)$$,
  '23514', 'FLAG_OVERRIDE_USER_NOT_IN_SCHOOL',
  'coordenação não cria override de usuário de outra escola');

-- Mesma exceção para UUID inexistente: sem oráculo de existência de conta.
SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, user_id, enabled)
    VALUES ('ffffffff-0000-0000-0000-000000000001', 'user',
            '10000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-0000000000ff', true)$$,
  '23514', 'FLAG_OVERRIDE_USER_NOT_IN_SCHOOL',
  'UUID inexistente devolve a mesma exceção que UUID de outra escola');

-- ------------------------------------------------------- domínio escolar
SELECT throws_ok(
  $$UPDATE public.students SET status = 'archived'$$,
  '42501', NULL, 'coordenação não escreve em students pelo cliente');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
