-- Resolver de feature flags.
--
-- ESTE ARQUIVO NÃO EXISTIA. O resolver determinístico era listado como uma das
-- correções da Revision 2.1 e como item do Gate ("precedência funciona",
-- "escola B não herda override A", "override por turma é único"), mas nenhuma
-- asserção o cobria.
--
-- Precedência implementada: escopo vence priority, sempre.
--   user > class > role > school > global
-- Consequência conhecida e ainda em aberto (ver GATE_M0A_EVIDENCE.md): um
-- override global NÃO funciona como kill-switch sobre um override de escola,
-- por mais alta que seja a priority. O teste abaixo fixa o comportamento atual
-- para que qualquer mudança de semântica seja deliberada.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(12);

\ir helpers/m0_fixture.psql

SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01');
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001',
                          '10000000-0000-0000-0000-000000000003'),
  false, 'sem override, vale o default_enabled do catálogo');

-- global(true)
RESET ROLE;
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, enabled, priority)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'global', true, 99);
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001',
                          '10000000-0000-0000-0000-000000000003'),
  true, 'override global se aplica na ausência de escopo mais específico');

-- school(false) com priority 0 vence global(true) com priority 99
RESET ROLE;
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled, priority)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
        '10000000-0000-0000-0000-000000000001', false, 0);
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001',
                          '10000000-0000-0000-0000-000000000003'),
  false, 'escopo de escola vence o global mesmo com priority menor');

-- class(true) vence school(false)
RESET ROLE;
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, class_id, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'class',
        '10000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000003', true);
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001',
                          '10000000-0000-0000-0000-000000000003'),
  true, 'escopo de turma vence o de escola');

-- user(false) vence class(true)
RESET ROLE;
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, user_id, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'user',
        '10000000-0000-0000-0000-000000000001',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01', false);
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001',
                          '10000000-0000-0000-0000-000000000003'),
  false, 'escopo de usuário vence o de turma');

-- role(student, true): aplica ao aluno, não ao professor
RESET ROLE;
DELETE FROM public.feature_flag_overrides WHERE scope_type IN ('user', 'class');
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, role, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'role',
        '10000000-0000-0000-0000-000000000001', 'student', true);
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001', NULL),
  true, 'override por papel alcança o aluno');

RESET ROLE;
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10');
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '10000000-0000-0000-0000-000000000001', NULL),
  false, 'override do papel student não alcança o professor');

-- Isolamento entre escolas: escola A ligada, escola B fica no default.
RESET ROLE;
DELETE FROM public.feature_flag_overrides;
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
        '10000000-0000-0000-0000-000000000001', true);
SELECT pg_temp.act_as('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb10');
SET LOCAL ROLE authenticated;
SELECT is(
  public.get_feature_flag('arena_beta', '20000000-0000-0000-0000-000000000001',
                          '20000000-0000-0000-0000-000000000003'),
  false, 'escola B não herda o override da escola A');

-- Antes de 0008 bastava a turma pertencer à escola: qualquer membro lia a flag
-- de qualquer turma.
RESET ROLE;
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01');
SET LOCAL ROLE authenticated;
SELECT throws_ok(
  $$SELECT public.get_feature_flag('arena_beta',
      '10000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000004')$$,
  'P0001', 'FORBIDDEN_SCOPE',
  'aluno não resolve flag de turma em que não está matriculado');

SELECT is(
  public.get_feature_flag('chave_que_nao_existe',
                          '10000000-0000-0000-0000-000000000001', NULL),
  false, 'chave desconhecida resolve como desligada');

-- Unicidade por escopo
RESET ROLE;
SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, class_id, enabled)
    SELECT 'ffffffff-0000-0000-0000-000000000001', 'class',
           '10000000-0000-0000-0000-000000000001',
           '10000000-0000-0000-0000-000000000003', v
      FROM (VALUES (true), (false)) AS t(v)$$,
  '23505', NULL, 'override por turma é único');

SELECT throws_ok(
  $$INSERT INTO public.feature_flag_overrides (flag_id, scope_type, enabled)
    SELECT 'ffffffff-0000-0000-0000-000000000001', 'global', v
      FROM (VALUES (true), (false)) AS t(v)$$,
  '23505', NULL, 'override global é único');

SELECT * FROM finish();
ROLLBACK;
