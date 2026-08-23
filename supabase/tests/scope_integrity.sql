-- Integridade de escopo no nível do banco.
--
-- ESTE ARQUIVO NÃO EXISTIA. As garantias abaixo — FKs compostas e triggers de
-- vínculo — eram justamente as que a suíte anterior desativava, porque cada
-- teste abria com `SET LOCAL session_replication_role = replica`. Com aquilo
-- ligado, uma matrícula apontando para a turma de outra escola era ACEITA e
-- ninguém percebia; remover as constraints não quebraria teste nenhum.
--
-- Roda como dono das tabelas (equivalente a service_role): o objetivo aqui é
-- provar que nem o backend consegue montar um estado inconsistente.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(12);

\ir helpers/m0_fixture.psql

-- --------------------------------------------------- FKs compostas de escopo
SELECT throws_ok(
  $$INSERT INTO public.classes (school_id, academic_year_id, name, grade, code)
    VALUES ('10000000-0000-0000-0000-000000000001',
            '20000000-0000-0000-0000-000000000002', 'Inválida', '6º ano', 'X1')$$,
  '23503', NULL, 'turma não aponta para ano letivo de outra escola');

SELECT throws_ok(
  $$INSERT INTO public.students (edugame_id, school_id, official_name, display_name)
    VALUES ('M0-A-900', '10000000-0000-0000-0000-000000000001', 'Novo', 'Novo');
    INSERT INTO public.enrollments (student_id, school_id, academic_year_id, class_id)
    SELECT id, '10000000-0000-0000-0000-000000000001',
           '10000000-0000-0000-0000-000000000002',
           '20000000-0000-0000-0000-000000000003'
      FROM public.students WHERE edugame_id = 'M0-A-900'$$,
  '23503', NULL, 'matrícula não aponta para turma de outra escola');

SELECT throws_ok(
  $$INSERT INTO public.teacher_assignments (user_id, school_id, academic_year_id, class_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '20000000-0000-0000-0000-000000000003')$$,
  '23503', NULL, 'atribuição docente não aponta para turma de outra escola');

-- ------------------------------------------------------- triggers de vínculo
SELECT throws_ok(
  $$INSERT INTO public.teacher_assignments (user_id, school_id, academic_year_id, class_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000004')$$,
  '23514', 'TEACHER_MEMBERSHIP_REQUIRED',
  'quem não tem vínculo docente ativo não recebe atribuição');

SELECT throws_ok(
  $$INSERT INTO public.guardian_student_links (guardian_user_id, student_id, school_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01',
            '10000000-0000-0000-0000-000000000012',
            '10000000-0000-0000-0000-000000000001')$$,
  '23514', 'FAMILY_MEMBERSHIP_REQUIRED',
  'quem não tem vínculo de família não vira responsável');

SELECT throws_ok(
  $$INSERT INTO public.guardian_student_links (guardian_user_id, student_id, school_id)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20',
            '20000000-0000-0000-0000-000000000011',
            '10000000-0000-0000-0000-000000000001')$$,
  '23514', 'GUARDIAN_STUDENT_SCHOOL_MISMATCH',
  'responsável não se vincula a estudante de outra escola');

-- --------------------------------------------------------------- unicidade
SELECT throws_ok(
  $$INSERT INTO public.enrollments (student_id, school_id, academic_year_id, class_id)
    VALUES ('10000000-0000-0000-0000-000000000011',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000004')$$,
  '23505', NULL, 'estudante não tem duas matrículas ativas no mesmo ano letivo');

SELECT throws_ok(
  $$INSERT INTO public.teacher_assignments (user_id, school_id, academic_year_id, class_id, subject_area)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000003', 'general')$$,
  '23505', NULL, 'atribuição docente ativa não se duplica');

SELECT throws_ok(
  $$INSERT INTO public.students (edugame_id, school_id, official_name, display_name)
    VALUES ('M0-A-001', '10000000-0000-0000-0000-000000000001', 'Clone', 'Clone')$$,
  '23505', NULL, 'edugame_id é globalmente único');

-- Invariante 5: encerrar em vez de apagar. Uma atribuição inativa não pode
-- bloquear a recontratação do mesmo professor para a mesma turma.
UPDATE public.teacher_assignments SET status = 'inactive', ended_at = now()
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10';

SELECT lives_ok(
  $$INSERT INTO public.teacher_assignments (user_id, school_id, academic_year_id, class_id, subject_area)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10',
            '10000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '10000000-0000-0000-0000-000000000003', 'general')$$,
  'atribuição encerrada não impede uma nova atribuição ativa');

-- ------------------------------------------------------- CHECKs de domínio
SELECT throws_ok(
  $$INSERT INTO public.academic_years (school_id, year, start_date, end_date)
    VALUES ('10000000-0000-0000-0000-000000000001', 2027, '2027-12-15', '2027-02-01')$$,
  '23514', NULL, 'ano letivo não termina antes de começar');

SELECT throws_ok(
  $$INSERT INTO public.schools (name, slug) VALUES ('Slug Ruim', 'Slug Com Espaço')$$,
  '23514', NULL, 'slug de escola respeita o formato');

SELECT * FROM finish();
ROLLBACK;
