-- Isolamento multi-escola.
-- Duas frentes: quem pertence a outra escola e quem não pertence a nenhuma.
-- A segunda importa porque uma conta recém-criada, ou com todos os vínculos
-- revogados, não pode enxergar nada — nem o catálogo de features.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(13);

\ir helpers/m0_fixture.psql

-- Mudança de flag na escola B, feita pelo backend, para checar depois que a
-- gestão da escola A não lê a auditoria da escola B.
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
        '20000000-0000-0000-0000-000000000001', true);

-- ------------------------------------------------- professor da escola B
SELECT pg_temp.act_as('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb10');
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.schools
            WHERE id = '10000000-0000-0000-0000-000000000001'), 0,
  'professor B não vê a escola A');
SELECT is((SELECT count(*)::int FROM public.classes
            WHERE school_id = '10000000-0000-0000-0000-000000000001'), 0,
  'professor B não vê turmas da escola A');
SELECT is((SELECT count(*)::int FROM public.students
            WHERE school_id = '10000000-0000-0000-0000-000000000001'), 0,
  'professor B não vê estudantes da escola A');
SELECT is((SELECT count(*)::int FROM public.enrollments
            WHERE school_id = '10000000-0000-0000-0000-000000000001'), 0,
  'professor B não vê matrículas da escola A');
SELECT is((SELECT count(*)::int FROM public.school_memberships
            WHERE school_id = '10000000-0000-0000-0000-000000000001'), 0,
  'professor B não vê vínculos da escola A');

SELECT throws_ok(
  $$SELECT public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001', NULL)$$,
  'P0001', 'FORBIDDEN_SCOPE',
  'professor B não resolve flag da escola A');

-- ------------------------------------------- conta sem nenhum vínculo ativo
RESET ROLE;
SELECT pg_temp.act_as('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb99');
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.students), 0,
  'conta sem vínculo não vê nenhum estudante');
SELECT is((SELECT count(*)::int FROM public.schools), 0,
  'conta sem vínculo não vê nenhuma escola');
SELECT is((SELECT count(*)::int FROM public.classes), 0,
  'conta sem vínculo não vê nenhuma turma');
SELECT is((SELECT count(*)::int FROM public.feature_flag_catalog), 0,
  'conta sem vínculo não lê o catálogo de features');
SELECT is((SELECT count(*)::int FROM public.user_profiles), 1,
  'conta sem vínculo enxerga apenas o próprio perfil');

SELECT throws_ok(
  $$SELECT public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001', NULL)$$,
  'P0001', 'FORBIDDEN_SCOPE',
  'conta sem vínculo não resolve flag de escola alguma');

-- ------------------------------------------------- auditoria não atravessa
RESET ROLE;
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa30');
SET LOCAL ROLE authenticated;

SELECT is((SELECT count(*)::int FROM public.audit_logs
            WHERE school_id = '20000000-0000-0000-0000-000000000001'), 0,
  'gestão da escola A não lê auditoria da escola B');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
