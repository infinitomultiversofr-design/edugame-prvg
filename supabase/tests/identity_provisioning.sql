-- Identidade: provisionamento de perfil e semântica de exclusão de conta.
--
-- ESTE ARQUIVO NÃO EXISTIA. Antes de 0008, public.user_profiles não tinha
-- nenhum caminho de criação — sem policy de INSERT, sem GRANT e sem trigger em
-- auth.users — então todo cadastro real nascia sem perfil e a policy
-- user_profiles_update_self era inalcançável.
--
-- A outra metade cobre o item do Gate "apagar auth.users não apaga students":
-- o histórico escolar sobrevive, a PII de autenticação some.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(13);

\ir helpers/m0_fixture.psql

-- ------------------------------------------------------- provisionamento
SELECT is(
  (SELECT count(*)::int FROM public.user_profiles),
  (SELECT count(*)::int FROM auth.users),
  'toda conta da fixture tem perfil');

INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES ('cccccccc-0000-0000-0000-000000000001', 'maria.souza@escola.br',
        '{"display_name": "Maria S."}');

SELECT is(
  (SELECT display_name FROM public.user_profiles
    WHERE user_id = 'cccccccc-0000-0000-0000-000000000001'),
  'Maria S.', 'display_name vem do metadata quando existe');

INSERT INTO auth.users (id, email)
VALUES ('cccccccc-0000-0000-0000-000000000002', 'joao.pereira@escola.br');

SELECT is(
  (SELECT display_name FROM public.user_profiles
    WHERE user_id = 'cccccccc-0000-0000-0000-000000000002'),
  'joao.pereira', 'sem metadata, display_name cai no local-part do e-mail');

INSERT INTO auth.users (id) VALUES ('cccccccc-0000-0000-0000-000000000003');

SELECT is(
  (SELECT display_name FROM public.user_profiles
    WHERE user_id = 'cccccccc-0000-0000-0000-000000000003'),
  'Usuário', 'sem e-mail nem metadata, ainda assim existe um display_name válido');

-- ------------------------------------------------- exclusão da conta Auth
DELETE FROM auth.users WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';

SELECT is(
  (SELECT count(*)::int FROM public.user_profiles
    WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01'),
  0, 'apagar a conta Auth remove o perfil (PII de autenticação)');

SELECT is(
  (SELECT count(*)::int FROM public.school_memberships
    WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01'),
  0, 'apagar a conta Auth remove os vínculos escolares');

SELECT is(
  (SELECT count(*)::int FROM public.students
    WHERE id = '10000000-0000-0000-0000-000000000011'),
  1, 'apagar a conta Auth preserva o registro escolar do estudante');

SELECT is(
  (SELECT user_id FROM public.students
    WHERE id = '10000000-0000-0000-0000-000000000011'),
  NULL::uuid, 'students.user_id vira NULL em vez de apagar a linha');

SELECT is(
  (SELECT edugame_id FROM public.students
    WHERE id = '10000000-0000-0000-0000-000000000011'),
  'M0-A-001'::text, 'o identificador escolar sobrevive à exclusão da conta');

SELECT is(
  (SELECT count(*)::int FROM public.enrollments
    WHERE student_id = '10000000-0000-0000-0000-000000000011'),
  1, 'a matrícula histórica sobrevive à exclusão da conta');

-- ------------------------------------------------------- edição do perfil
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02');
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$UPDATE public.user_profiles SET display_name = 'A2 escolheu'
     WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02'$$,
  'usuário edita o próprio display_name');

-- O perfil continua sendo criado pelo servidor: o cliente não inventa contas.
SELECT throws_ok(
  $$INSERT INTO public.user_profiles (user_id, display_name)
    VALUES ('cccccccc-0000-0000-0000-000000000009', 'forjado')$$,
  '42501', NULL, 'cliente não insere perfil diretamente');

-- A policy restringe o UPDATE ao próprio user_id, então isto não levanta erro:
-- simplesmente não alcança linha nenhuma. A verificação precisa ser feita fora
-- do papel `authenticated`, que não enxerga o perfil alheio nem para conferir.
UPDATE public.user_profiles SET display_name = 'invadido'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';

RESET ROLE;

SELECT isnt(
  (SELECT display_name FROM public.user_profiles
    WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10'),
  'invadido', 'usuário não edita perfil alheio');
SELECT * FROM finish();
ROLLBACK;
