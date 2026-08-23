-- Auditoria.
--
-- ESTE ARQUIVO NÃO EXISTIA. O Gate M0-A pede "alteração gera audit log",
-- "estudante não insere audit diretamente" e "chaves de raw IP/User-Agent
-- conhecidas são rejeitadas"; nada disso tinha asserção. O runner
-- m0-gate.mjs chegava a testar a rejeição de PII, mas com o cliente
-- service_role — o que valida a constraint, não a negação ao aluno.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path TO extensions, public;
SELECT plan(13);

\ir helpers/m0_fixture.psql

-- --------------------------------------------------- cobertura da auditoria
INSERT INTO public.feature_flag_overrides (flag_id, scope_type, school_id, enabled)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'school',
        '10000000-0000-0000-0000-000000000001', true);

SELECT ok(
  EXISTS (SELECT 1 FROM public.audit_logs
           WHERE action = 'feature_flag_override_created'),
  'mudança de feature flag gera registro de auditoria');

UPDATE public.school_memberships SET role = 'director'
 WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa30';

SELECT is(
  (SELECT diff_summary -> 'role' ->> 'to' FROM public.audit_logs
    WHERE action = 'school_memberships_update' LIMIT 1),
  'director', 'mudança de papel registra a transição');

UPDATE public.students SET status = 'transferred', official_name = 'Nome Trocado'
 WHERE id = '10000000-0000-0000-0000-000000000011';

SELECT is(
  (SELECT diff_summary -> 'status' ->> 'to' FROM public.audit_logs
    WHERE action = 'students_update' LIMIT 1),
  'transferred', 'mudança de status de estudante é auditada');

UPDATE public.enrollments SET status = 'inactive'
 WHERE student_id = '10000000-0000-0000-0000-000000000012';

SELECT ok(
  EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'enrollments_update'),
  'mudança de matrícula é auditada');

UPDATE public.guardian_student_links SET status = 'revoked'
 WHERE guardian_user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa20';

SELECT ok(
  EXISTS (SELECT 1 FROM public.audit_logs
           WHERE action = 'guardian_student_links_update'),
  'revogação de vínculo de responsável é auditada');

-- A auditoria registra autoridade e estado, nunca dado pessoal: o UPDATE acima
-- trocou official_name e isso não pode aparecer em lugar nenhum.
SELECT is(
  (SELECT count(*)::int FROM public.audit_logs
    WHERE (diff_summary::text || metadata::text) ILIKE '%Nome Trocado%'),
  0, 'auditoria não carrega nome de estudante');

-- ----------------------------------------------------------- PII de rede
SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type, metadata)
    VALUES ('t', 'system', '{"ip_address": "203.0.113.7"}')$$,
  '23514', NULL, 'metadata com ip_address no topo é rejeitada');

-- Antes de 0008 o CHECK só olhava as chaves de primeiro nível.
SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type, metadata)
    VALUES ('t', 'system', '{"ctx": {"request": {"ip_address": "203.0.113.7"}}}')$$,
  '23514', NULL, 'metadata com ip_address aninhado é rejeitada');

-- ...e comparava nome exato, então clientIp passava.
SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type, metadata)
    VALUES ('t', 'system', '{"clientIp": "203.0.113.7"}')$$,
  '23514', NULL, 'variação de nome (clientIp) é rejeitada');

SELECT throws_ok(
  $$INSERT INTO public.audit_logs (action, resource_type, diff_summary)
    VALUES ('t', 'system', '{"trace": [{"User-Agent": "Mozilla/5.0"}]}')$$,
  '23514', NULL, 'User-Agent dentro de array em diff_summary é rejeitado');

SELECT lives_ok(
  $$INSERT INTO public.audit_logs (action, resource_type, school_id, metadata)
    VALUES ('t', 'system', '10000000-0000-0000-0000-000000000001',
            '{"origem": "backend", "motivo": "rollout"}')$$,
  'metadata sem PII de rede é aceita');

-- ------------------------------------------------------------- leitura
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01');
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*)::int FROM public.audit_logs), 0,
  'estudante não lê auditoria');

RESET ROLE;
SELECT pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa30');
SET LOCAL ROLE authenticated;
SELECT ok((SELECT count(*) FROM public.audit_logs) > 0,
  'gestão lê a auditoria da própria escola');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
