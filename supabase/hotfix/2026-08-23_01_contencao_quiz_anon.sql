-- =========================================================================
-- CONTENÇÃO — remove o acesso anônimo aberto criado por supabase/sql/00_quiz_legacy.sql
--
-- Projeto alvo: o Supabase do app publicado (ref amvfodigcecsbvlmobrx)
-- Rodar no SQL Editor do Supabase.
--
-- O QUE ISTO PARA
--   1. anon lia public.students inteiro (nomes de menores, todas as colunas);
--   2. anon lia public.questions com correct_answer — o gabarito ia para o
--      navegador e a correção era feita em JS;
--   3. anon lia public.quiz_responses com USING (true) — as respostas de
--      todos os alunos;
--   4. anon inseria em public.transactions com uma policy que só checava
--      points = 1, created_by = 'Quiz Online' e rule_id. Sem checagem de
--      student_id, sem exigir resposta correspondente, sem limite: injeção
--      ilimitada de pontos para qualquer aluno, sem login, usando a chave
--      anon que está publicada no bundle.
--
-- EFEITO COLATERAL
--   A rota /quiz para de funcionar até você aplicar o arquivo 02 e trocar as
--   chamadas no app. Isso é intencional: não existe forma de manter o quiz
--   client-side e seguro ao mesmo tempo.
--
-- Este script é idempotente.
-- =========================================================================

BEGIN;

-- 1. Policies anônimas ------------------------------------------------------
DROP POLICY IF EXISTS "quiz_public_read_classes"     ON public.classes;
DROP POLICY IF EXISTS "quiz_public_read_students"    ON public.students;
DROP POLICY IF EXISTS "quiz_public_read_questions"   ON public.questions;
DROP POLICY IF EXISTS "quiz_public_read_rules"       ON public.rules;
DROP POLICY IF EXISTS "quiz_public_insert_responses" ON public.quiz_responses;
DROP POLICY IF EXISTS "quiz_public_read_responses"   ON public.quiz_responses;
DROP POLICY IF EXISTS "quiz_public_insert_tx"        ON public.transactions;

-- 2. Grants de tabela para anon ---------------------------------------------
REVOKE ALL ON public.classes        FROM anon;
REVOKE ALL ON public.students       FROM anon;
REVOKE ALL ON public.questions      FROM anon;
REVOKE ALL ON public.rules          FROM anon;
REVOKE ALL ON public.quiz_responses FROM anon;
REVOKE ALL ON public.transactions   FROM anon;

-- 3. RLS ligada nas tabelas envolvidas (falha fechada) ----------------------
ALTER TABLE public.classes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions   ENABLE ROW LEVEL SECURITY;

COMMIT;

-- =========================================================================
-- CONFERÊNCIA — rode depois e confirme que não sobrou nada para anon.
-- Ambas as consultas devem voltar VAZIAS.
-- =========================================================================

-- 3a. Nenhuma policy deve mencionar o papel anon:
--
-- SELECT tablename, policyname, roles
--   FROM pg_policies
--  WHERE schemaname = 'public'
--    AND 'anon' = ANY (roles);

-- 3b. Nenhum grant de tabela deve sobrar para anon:
--
-- SELECT table_name, privilege_type
--   FROM information_schema.role_table_grants
--  WHERE table_schema = 'public' AND grantee = 'anon';

-- =========================================================================
-- AVALIAÇÃO DO DANO — quanto ponto pode ter entrado por injeção.
-- Não conclui nada sozinho: transações legítimas do quiz têm a mesma
-- assinatura. O sinal de abuso é volume anômalo por aluno/semana.
-- =========================================================================
--
-- SELECT t.week_start, t.student_id, count(*) AS lancamentos,
--        count(DISTINCT t.subject) AS materias, sum(t.points) AS pontos
--   FROM public.transactions t
--  WHERE t.created_by = 'Quiz Online'
--  GROUP BY 1, 2
-- HAVING count(*) > 8            -- o quiz legítimo dá no máximo 1 por matéria
--  ORDER BY lancamentos DESC;
--
-- Compare com as respostas efetivamente registradas:
--
-- SELECT t.student_id, t.week_start,
--        count(*) FILTER (WHERE t.id IS NOT NULL) AS transacoes,
--        (SELECT count(*) FROM public.quiz_responses r
--          WHERE r.student_id = t.student_id AND r.week_start = t.week_start
--            AND r.is_correct IS TRUE) AS acertos_registrados
--   FROM public.transactions t
--  WHERE t.created_by = 'Quiz Online'
--  GROUP BY t.student_id, t.week_start
--  ORDER BY 3 DESC;
--
-- Transações sem acerto correspondente são o indício mais direto de injeção.
