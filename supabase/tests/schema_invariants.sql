-- Invariantes estruturais do M0.
-- A versão anterior deste arquivo só verificava "esta tabela existe" (8 asserções)
-- e não testava nenhum dos invariantes declarados no cabeçalho das migrations.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

-- pgTAP chama as próprias funções internas (_set, _get, ...) sem qualificar
-- schema. Sem incluir `extensions` no search_path, plan() falha com
-- "function _set(unknown, integer) does not exist" e o arquivo inteiro é
-- abortado antes da primeira asserção — era o que acontecia com esta suíte.
SET LOCAL search_path TO extensions, public;

SELECT plan(16);

-- -------------------------------------------------------------------------
-- Invariante 1 — nenhuma identidade operacional usa serial/bigserial/identity
-- -------------------------------------------------------------------------
SELECT is(
  (SELECT count(*)::int
     FROM pg_attribute a
     JOIN pg_class c ON c.oid = a.attrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND (a.attidentity <> ''
           OR coalesce(pg_get_expr(d.adbin, d.adrelid), '') LIKE 'nextval%')),
  0,
  'nenhuma coluna serial/bigserial/identity em public'
);

SELECT is(
  (SELECT count(*)::int
     FROM pg_constraint con
     JOIN pg_class c ON c.oid = con.conrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = con.conkey[1]
    WHERE n.nspname = 'public'
      AND con.contype = 'p'
      AND array_length(con.conkey, 1) = 1
      AND a.atttypid <> 'uuid'::regtype),
  0,
  'toda PK simples de public é uuid'
);

-- -------------------------------------------------------------------------
-- RLS: habilitada em tudo e com ao menos uma policy (falha fechada)
-- -------------------------------------------------------------------------
SELECT is(
  (SELECT count(*)::int
     FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity),
  0,
  'toda tabela de public tem RLS habilitada'
);

SELECT is(
  (SELECT count(*)::int
     FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity
      AND NOT EXISTS (
        SELECT 1 FROM pg_policies p
         WHERE p.schemaname = 'public' AND p.tablename = c.relname)),
  0,
  'nenhuma tabela com RLS ligada e zero policies'
);

-- Escrita de cliente só existe onde foi decidida: feature_flag_overrides.
SELECT is(
  (SELECT coalesce(string_agg(DISTINCT tablename, ','), '')
     FROM pg_policies
    WHERE schemaname = 'public' AND cmd IN ('INSERT', 'DELETE')),
  'feature_flag_overrides',
  'INSERT/DELETE por cliente só em feature_flag_overrides'
);

-- -------------------------------------------------------------------------
-- Isolamento de escopo por FK composta (não confiar só na aplicação)
-- -------------------------------------------------------------------------
SELECT has_index('public', 'academic_years', 'academic_year_id_school_unique',
  'academic_years(id, school_id) é única — alvo de FK composta');
SELECT has_index('public', 'classes', 'classes_id_school_unique',
  'classes(id, school_id) é única — alvo de FK composta');
SELECT has_index('public', 'classes', 'classes_id_school_year_unique',
  'classes(id, school_id, academic_year_id) é única — alvo de FK composta');

SELECT ok(
  EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'classes_year_same_school_fk'),
  'classes_year_same_school_fk impede turma em ano letivo de outra escola'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'enrollment_class_scope_fk'),
  'enrollment_class_scope_fk impede matrícula fora do escopo turma/ano/escola'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'teacher_assignment_class_scope_fk'),
  'teacher_assignment_class_scope_fk impede atribuição fora do escopo'
);

-- -------------------------------------------------------------------------
-- Superfície de autorização
-- -------------------------------------------------------------------------
SELECT is(
  (SELECT count(*)::int
     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('private', 'public')
      AND p.prosecdef
      AND NOT ('search_path=""' = ANY (coalesce(p.proconfig, ARRAY[]::text[])))),
  0,
  'toda função SECURITY DEFINER fixa search_path vazio'
);

-- Regressão do oráculo de vínculos: nenhum helper aceita um usuário arbitrário.
-- Os helpers leem auth.uid() internamente; quem sobrar com assinatura antiga
-- volta a permitir perguntar sobre terceiros.
SELECT is(
  (SELECT count(*)::int
     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private'
      AND p.proname IN ('is_member_of_school','is_student_user','is_teacher_of_class',
                        'is_teacher_of_student','is_guardian_of_student',
                        'can_manage_school','can_manage_flags',
                        'can_read_student','can_read_class')
      AND p.pronargs <> 1),
  0,
  'helpers de autorização recebem só o recurso, nunca o usuário'
);

SELECT is(
  (SELECT count(*)::int
     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private'
      AND has_function_privilege('anon', p.oid, 'EXECUTE')),
  0,
  'anon não executa nada em private'
);

SELECT ok(
  NOT has_table_privilege('anon', 'public.students', 'SELECT'),
  'anon não lê students'
);

-- -------------------------------------------------------------------------
-- Provisionamento de identidade
-- -------------------------------------------------------------------------
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'auth' AND c.relname = 'users'
       AND t.tgname = 'on_auth_user_created' AND NOT t.tgisinternal),
  'auth.users provisiona user_profiles automaticamente'
);

SELECT * FROM finish();
ROLLBACK;
