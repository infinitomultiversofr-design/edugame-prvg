BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT extensions.plan(4);


-- Fixture local: usa UUIDs sintéticos. Como as FKs apontam para auth.users,
-- desabilitamos triggers/FKs APENAS dentro desta transação de teste.
SET LOCAL session_replication_role = replica;

INSERT INTO public.schools (id, name, short_name, slug) VALUES
('10000000-0000-0000-0000-000000000001','Escola A','A','m0-test-a'),
('20000000-0000-0000-0000-000000000001','Escola B','B','m0-test-b');

INSERT INTO public.academic_years (id, school_id, year, start_date, end_date) VALUES
('10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001',2026,'2026-02-01','2026-12-15'),
('20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001',2026,'2026-02-01','2026-12-15');

INSERT INTO public.classes (id, school_id, academic_year_id, name, grade, code) VALUES
('10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','6A','6º ano','6A'),
('10000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','7A','7º ano','7A'),
('20000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','6A-B','6º ano','6A');

-- Principals:
-- student A1 = aaaa...01
-- student A2 = aaaa...02
-- teacher A = aaaa...10
-- family A = aaaa...20
-- coordinator A = aaaa...30
-- teacher B = bbbb...10
INSERT INTO public.school_memberships (id,user_id,school_id,role,status) VALUES
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01','10000000-0000-0000-0000-000000000001','student','active'),
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02','10000000-0000-0000-0000-000000000001','student','active'),
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10','10000000-0000-0000-0000-000000000001','teacher','active'),
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20','10000000-0000-0000-0000-000000000001','family','active'),
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa30','10000000-0000-0000-0000-000000000001','coordinator','active'),
(gen_random_uuid(),'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb10','20000000-0000-0000-0000-000000000001','teacher','active');

INSERT INTO public.students (
  id, edugame_id, user_id, school_id, official_name, display_name
) VALUES
('10000000-0000-0000-0000-000000000011','M0-A-001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01','10000000-0000-0000-0000-000000000001','Aluno A1','Aluno A1'),
('10000000-0000-0000-0000-000000000012','M0-A-002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02','10000000-0000-0000-0000-000000000001','Aluno A2','Aluno A2'),
('20000000-0000-0000-0000-000000000011','M0-B-001',NULL,'20000000-0000-0000-0000-000000000001','Aluno B1','Aluno B1');

INSERT INTO public.enrollments (
  id, student_id, school_id, academic_year_id, class_id, status
) VALUES
(gen_random_uuid(),'10000000-0000-0000-0000-000000000011','10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003','active'),
(gen_random_uuid(),'10000000-0000-0000-0000-000000000012','10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003','active'),
(gen_random_uuid(),'20000000-0000-0000-0000-000000000011','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003','active');

INSERT INTO public.teacher_assignments (
  id,user_id,school_id,academic_year_id,class_id,subject_area
) VALUES
(gen_random_uuid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10','10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003','general'),
(gen_random_uuid(),'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb10','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000003','general');

INSERT INTO public.guardian_student_links (
  id,guardian_user_id,student_id,school_id,status,verified_at
) VALUES (
  gen_random_uuid(),
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20',
  '10000000-0000-0000-0000-000000000011',
  '10000000-0000-0000-0000-000000000001',
  'active',
  now()
);

SET LOCAL session_replication_role = origin;


SELECT set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10', true);
SELECT set_config(
  'request.jwt.claims',
  json_build_object('sub','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10','role','authenticated')::text,
  true
);
SET LOCAL ROLE authenticated;

SELECT extensions.is((SELECT count(*)::int FROM public.students), 2, 'teacher vê estudantes da turma atribuída');
SELECT extensions.is((SELECT count(*)::int FROM public.students WHERE school_id = '20000000-0000-0000-0000-000000000001'), 0, 'teacher não vê estudante de outra escola');
SELECT extensions.is((SELECT count(*)::int FROM public.classes), 1, 'teacher vê apenas turma atribuída');
SELECT extensions.is((SELECT count(*)::int FROM public.teacher_assignments), 1, 'teacher vê apenas a própria atribuição');

RESET ROLE;
SELECT * FROM extensions.finish();
ROLLBACK;
