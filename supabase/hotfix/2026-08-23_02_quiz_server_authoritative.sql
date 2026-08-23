-- =========================================================================
-- QUIZ SERVER-AUTHORITATIVE — substitui o acesso direto às tabelas por três RPCs
--
-- Rodar DEPOIS de 2026-08-23_01_contencao_quiz_anon.sql, no SQL Editor.
--
-- PRINCÍPIO
--   O navegador nunca recebe o gabarito, nunca decide acerto e nunca escreve
--   no ledger de pontos. Ele manda as respostas; o servidor corrige, grava e
--   só então devolve o resultado.
--
-- O QUE ISTO RESOLVE
--   ✓ gabarito não sai mais do servidor antes da submissão
--   ✓ pontos passam a ser consequência da correção, não entrada do cliente
--   ✓ um lançamento por aluno/semana/matéria, garantido por índice único
--   ✓ quiz_responses deixa de ser legível por terceiros
--   ✓ o roster exposto cai para os alunos ativos da turma do código informado
--
-- O QUE ISTO **NÃO** RESOLVE
--   O /quiz não tem login. Quem souber o código da turma continua podendo
--   responder no lugar de um colega, escolhendo o nome dele na lista. Isso é
--   inerente ao fluxo sem autenticação e não tem correção possível no banco.
--   As saídas reais são código de acesso por aluno ou Auth de verdade — que é
--   o que a fundação M0 (school_memberships + RLS) entrega. Trate este arquivo
--   como contenção com o quiz funcionando, não como desenho final.
--
-- ===== SUPOSIÇÕES DE SCHEMA ==============================================
-- Reconstruí as colunas a partir do código do app, não do banco (o MCP do
-- Supabase não estava autorizado). CONFIRA antes de rodar:
--
--   classes(id uuid, name text, grade text, quiz_code text)
--   students(id uuid, name text, class_id uuid, active boolean)
--   questions(id uuid, subject text, question_text text, question_type text,
--             options jsonb|text[], correct_answer text,
--             correct_answer_normalized text, queue_order int,
--             year_group text, active boolean, used_in_week ?)
--   rules(id uuid, name text, points int, type text)
--   quiz_responses(id uuid, student_id uuid, question_id uuid,
--                  week_start date, answer_given text, is_correct boolean)
--   transactions(id uuid, student_id uuid, class_id uuid, rule_id uuid,
--                points int, week_start date, subject text, comment text,
--                created_by text)
--
-- Confira rapidamente com:
--   select table_name, column_name, data_type
--     from information_schema.columns
--    where table_schema='public'
--      and table_name in ('classes','students','questions','rules',
--                         'quiz_responses','transactions')
--    order by table_name, ordinal_position;
--
-- Se `options` for text[] em vez de jsonb, troque to_jsonb(q.options) por
-- to_jsonb(q.options) mesmo — funciona nos dois casos.
-- =========================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 0. Idempotência: sem estes índices, "uma submissão por semana" é só uma
--    checagem que dá para correr por fora com requisições paralelas.
-- -------------------------------------------------------------------------
-- Se algum destes falhar, já existe duplicata. Investigue antes com:
--   select student_id, question_id, week_start, count(*)
--     from public.quiz_responses group by 1,2,3 having count(*) > 1;
--   select student_id, week_start, subject, count(*)
--     from public.transactions where created_by = 'Quiz Online'
--    group by 1,2,3 having count(*) > 1;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_responses_once_per_week
  ON public.quiz_responses (student_id, question_id, week_start);

CREATE UNIQUE INDEX IF NOT EXISTS transactions_quiz_once_per_subject_week
  ON public.transactions (student_id, week_start, subject)
  WHERE created_by = 'Quiz Online';

-- -------------------------------------------------------------------------
-- 1. Normalização de resposta — espelha o normalizeAnswer() do app
--    (remove acento, caixa alta, trim).
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.quiz_normalize(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT upper(btrim(translate(
    coalesce(p_text, ''),
    'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
    'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
  )));
$$;

REVOKE ALL ON FUNCTION public.quiz_normalize(text) FROM PUBLIC, anon, authenticated;

-- -------------------------------------------------------------------------
-- 2. Turma + roster da turma, a partir do código
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.quiz_lookup_class(p_quiz_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_class record;
  v_students jsonb;
BEGIN
  IF p_quiz_code IS NULL OR btrim(p_quiz_code) = '' THEN
    RAISE EXCEPTION USING MESSAGE = 'QUIZ_CODE_REQUIRED';
  END IF;

  SELECT c.id, c.name, c.grade
    INTO v_class
    FROM public.classes c
   WHERE upper(btrim(c.quiz_code)) = upper(btrim(p_quiz_code));

  IF v_class.id IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'CLASS_NOT_FOUND';
  END IF;

  IF substring(coalesce(v_class.grade, '') from '(\d+)') IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'CLASS_WITHOUT_YEAR_GROUP';
  END IF;

  -- Só id e nome, só ativos, só desta turma. Nenhuma outra coluna de aluno
  -- sai daqui.
  SELECT coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'name', s.name)
                            ORDER BY s.name), '[]'::jsonb)
    INTO v_students
    FROM public.students s
   WHERE s.class_id = v_class.id
     AND s.active IS TRUE;

  RETURN jsonb_build_object(
    'class', jsonb_build_object('id', v_class.id, 'name', v_class.name, 'grade', v_class.grade),
    'students', v_students
  );
END;
$$;

-- -------------------------------------------------------------------------
-- 3. Questões da semana — SEM correct_answer
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.quiz_start(p_student_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_week date := date_trunc('week', current_date)::date;  -- segunda-feira
  v_year text;
  v_questions jsonb;
BEGIN
  SELECT substring(coalesce(c.grade, '') from '(\d+)')
    INTO v_year
    FROM public.students s
    JOIN public.classes c ON c.id = s.class_id
   WHERE s.id = p_student_id
     AND s.active IS TRUE;

  IF v_year IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'STUDENT_NOT_FOUND';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.quiz_responses r
     WHERE r.student_id = p_student_id AND r.week_start = v_week
  ) THEN
    RAISE EXCEPTION USING MESSAGE = 'ALREADY_SUBMITTED_THIS_WEEK';
  END IF;

  -- Uma questão por matéria, a de menor queue_order. correct_answer e
  -- correct_answer_normalized NÃO entram no retorno.
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'id', x.id,
           'subject', x.subject,
           'question_text', x.question_text,
           'question_type', x.question_type,
           'options', to_jsonb(x.options)
         ) ORDER BY x.subject), '[]'::jsonb)
    INTO v_questions
    FROM (
      SELECT DISTINCT ON (q.subject)
             q.id, q.subject, q.question_text, q.question_type, q.options
        FROM public.questions q
       WHERE q.year_group = v_year
         AND q.active IS TRUE
         AND q.used_in_week IS NULL
       ORDER BY q.subject, q.queue_order ASC
    ) x;

  RETURN v_questions;
END;
$$;

-- -------------------------------------------------------------------------
-- 4. Submissão — correção, gravação e ledger, tudo no servidor
-- -------------------------------------------------------------------------
-- p_answers: [{"question_id": "<uuid>", "answer": "<texto>"}, ...]
CREATE OR REPLACE FUNCTION public.quiz_submit(p_student_id uuid, p_answers jsonb)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_week date := date_trunc('week', current_date)::date;
  v_class_id uuid;
  v_year text;
  v_rule_id uuid;
  v_rule_points int;
  v_item jsonb;
  v_q record;
  v_given text;
  v_is_correct boolean;
  v_pending boolean;
  v_feedback jsonb := '[]'::jsonb;
  v_count int := 0;
BEGIN
  IF jsonb_typeof(p_answers) <> 'array' THEN
    RAISE EXCEPTION USING MESSAGE = 'ANSWERS_MUST_BE_ARRAY';
  END IF;

  IF jsonb_array_length(p_answers) > 20 THEN
    RAISE EXCEPTION USING MESSAGE = 'TOO_MANY_ANSWERS';
  END IF;

  SELECT s.class_id, substring(coalesce(c.grade, '') from '(\d+)')
    INTO v_class_id, v_year
    FROM public.students s
    JOIN public.classes c ON c.id = s.class_id
   WHERE s.id = p_student_id
     AND s.active IS TRUE;

  IF v_class_id IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'STUDENT_NOT_FOUND';
  END IF;

  -- Barreira de reenvio. O índice único em quiz_responses é a garantia real;
  -- isto só devolve um erro legível em vez de violação de constraint.
  IF EXISTS (
    SELECT 1 FROM public.quiz_responses r
     WHERE r.student_id = p_student_id AND r.week_start = v_week
  ) THEN
    RAISE EXCEPTION USING MESSAGE = 'ALREADY_SUBMITTED_THIS_WEEK';
  END IF;

  SELECT r.id, r.points INTO v_rule_id, v_rule_points
    FROM public.rules r
   WHERE r.name = 'Quiz - Acerto disciplina';

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_answers)
  LOOP
    -- A questão precisa ser elegível para ESTE aluno. Sem isto, dava para
    -- submeter ids de questões de outro ano/inativas e pontuar.
    SELECT q.id, q.subject, q.question_type, q.correct_answer,
           q.correct_answer_normalized
      INTO v_q
      FROM public.questions q
     WHERE q.id = (v_item ->> 'question_id')::uuid
       AND q.year_group = v_year
       AND q.active IS TRUE
       AND q.used_in_week IS NULL;

    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    v_count := v_count + 1;
    v_given := btrim(coalesce(v_item ->> 'answer', ''));

    IF v_q.question_type = 'multiple_choice' THEN
      v_pending := false;
      v_is_correct := public.quiz_normalize(v_given) = coalesce(
        nullif(btrim(v_q.correct_answer_normalized), ''),
        public.quiz_normalize(v_q.correct_answer)
      );
    ELSE
      -- Dissertativa não é corrigida automaticamente: fica para o professor.
      v_pending := true;
      v_is_correct := NULL;
    END IF;

    INSERT INTO public.quiz_responses
      (student_id, question_id, week_start, answer_given, is_correct)
    VALUES
      (p_student_id, v_q.id, v_week, v_given, v_is_correct)
    ON CONFLICT (student_id, question_id, week_start) DO NOTHING;

    IF v_is_correct IS TRUE AND v_rule_id IS NOT NULL THEN
      INSERT INTO public.transactions
        (student_id, class_id, rule_id, points, week_start, subject, comment, created_by)
      VALUES
        (p_student_id, v_class_id, v_rule_id, coalesce(v_rule_points, 1),
         v_week, v_q.subject, 'Quiz: ' || v_q.subject, 'Quiz Online')
      ON CONFLICT DO NOTHING;
    END IF;

    -- O gabarito só aparece agora, depois de gravada a resposta.
    v_feedback := v_feedback || jsonb_build_object(
      'question_id', v_q.id,
      'subject', v_q.subject,
      'given', v_given,
      'correct', coalesce(v_is_correct, false),
      'pending', v_pending,
      'correct_answer', CASE WHEN v_pending THEN NULL ELSE v_q.correct_answer END
    );
  END LOOP;

  IF v_count = 0 THEN
    RAISE EXCEPTION USING MESSAGE = 'NO_VALID_ANSWERS';
  END IF;

  RETURN v_feedback;
END;
$$;

-- -------------------------------------------------------------------------
-- 5. Grants — anon executa só as três RPCs, nada de tabela
-- -------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.quiz_lookup_class(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.quiz_start(uuid)        FROM PUBLIC;
REVOKE ALL ON FUNCTION public.quiz_submit(uuid, jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.quiz_lookup_class(text)   TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.quiz_start(uuid)          TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.quiz_submit(uuid, jsonb)  TO anon, authenticated;

COMMIT;

-- =========================================================================
-- TESTE DE FUMAÇA (rode com um quiz_code real)
--
--   select public.quiz_lookup_class('8A-2026');
--   select public.quiz_start('<student_uuid>');
--   select public.quiz_submit('<student_uuid>',
--     '[{"question_id":"<uuid>","answer":"B"}]'::jsonb);
--
-- Confirme que quiz_start NÃO devolve correct_answer, e que a segunda
-- chamada de quiz_submit para o mesmo aluno na mesma semana levanta
-- ALREADY_SUBMITTED_THIS_WEEK.
-- =========================================================================
