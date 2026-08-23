/*
 * EDUGAME — M0 FOUNDATION
 * 0008 — Hardening de autorização, provisionamento e auditoria
 *
 * INVARIANTES DE IDENTIDADE E AUTORIDADE
 * 1. Nenhuma identidade operacional usa serial/bigserial.
 *    PKs operacionais usam UUID; relações puramente associativas podem usar chaves compostas.
 * 2. Códigos humanos (turma, habilidade, ID EduGame etc.) não substituem FKs.
 * 3. O navegador nunca é autoridade para pontuação, acerto, desbloqueio ou identidade de outro usuário.
 * 4. Operações sensíveis posteriores devem ser server-authoritative, idempotentes e auditáveis.
 * 5. Entidades históricas são inativadas/arquivadas; não dependemos de DELETE CASCADE para “limpeza”.
 *
 * O QUE ESTA MIGRATION CORRIGE (achados do review de 0001–0007)
 *
 *  B1  Vínculo suspenso mantinha acesso. is_teacher_of_class/is_teacher_of_student
 *      liam apenas teacher_assignments e is_guardian_of_student apenas o status do
 *      vínculo; nenhum checava school_memberships.status. Suspender um professor ou
 *      um responsável não revogava a leitura dos dados do estudante.
 *
 *  A1  Os helpers private.* recebiam p_user_id como argumento e tinham EXECUTE para
 *      `authenticated`, virando um oráculo: qualquer usuário autenticado podia
 *      perguntar sobre vínculos de terceiros que o RLS esconde. Agora todos leem
 *      auth.uid() internamente e não aceitam sujeito arbitrário.
 *
 *  B4  public.user_profiles não tinha nenhum caminho de criação (sem policy de
 *      INSERT, sem GRANT, sem trigger em auth.users). Todo cadastro nascia sem
 *      perfil e user_profiles_update_self era inalcançável.
 *
 *  A2  Override de flag com scope_type='user' aceitava qualquer UUID de auth.users,
 *      inclusive de outra escola, e o erro de FK distinguia UUID inexistente de
 *      UUID existente (oráculo de existência de conta).
 *
 *  M1  get_feature_flag validava apenas vínculo com a escola: um estudante lia a
 *      flag de uma turma em que não está matriculado.
 *
 *  M4  O CHECK de PII do audit era de topo e por nome exato: {"ctx":{"ip_address"}}
 *      e {"clientIp"} passavam.
 *
 *  M5  Só mudanças de feature flag eram auditadas. Vínculo escolar, papel, vínculo
 *      de responsável, atribuição docente e status de estudante não geravam registro.
 *
 *  L4  feature_flag_catalog era legível com USING (true).
 *
 *  L6  teacher_assignments não tinha status/ended_at: desligar professor exigia
 *      DELETE, contra o invariante 5.
 *
 * NÃO ALTERADO DE PROPÓSITO (exige ADR — ver GATE_M0A_EVIDENCE.md)
 *  - Precedência do resolver de flags: escopo sempre vence priority, então um
 *    override 'global' não funciona como kill-switch sobre um override de escola.
 *  - Ausência de FORCE ROW LEVEL SECURITY: ligá-lo sujeitaria o dono das tabelas às
 *    policies e quebraria os triggers de auditoria, que inserem em audit_logs sem
 *    policy de INSERT. Precisa de decisão conjunta antes de mudar.
 */

BEGIN;

-- =========================================================================
-- 1. teacher_assignments: inativação em vez de DELETE (L6)
-- =========================================================================

ALTER TABLE public.teacher_assignments
  ADD COLUMN status text NOT NULL DEFAULT 'active',
  ADD COLUMN ended_at timestamptz;

ALTER TABLE public.teacher_assignments
  ADD CONSTRAINT teacher_assignment_status_valid
    CHECK (status IN ('active', 'inactive')),
  ADD CONSTRAINT teacher_assignment_end_valid
    CHECK (ended_at IS NULL OR status = 'inactive');

-- A unicidade passa a valer só entre atribuições vigentes, para que uma
-- atribuição encerrada não impeça a recontratação do mesmo professor.
ALTER TABLE public.teacher_assignments
  DROP CONSTRAINT teacher_assignment_unique;

CREATE UNIQUE INDEX teacher_assignment_active_unique
  ON public.teacher_assignments(user_id, class_id, subject_area)
  WHERE status = 'active';

-- =========================================================================
-- 2. Helpers de autorização sem sujeito arbitrário (A1) e sensíveis a
--    school_memberships.status (B1)
-- =========================================================================

CREATE OR REPLACE FUNCTION private.has_any_active_membership()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = (SELECT auth.uid())
      AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.is_member_of_school(p_school_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = (SELECT auth.uid())
      AND m.school_id = p_school_id
      AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.has_any_role_in_school(
  p_school_id uuid,
  p_roles text[]
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = (SELECT auth.uid())
      AND m.school_id = p_school_id
      AND m.status = 'active'
      AND m.role = ANY (p_roles)
  );
$$;

CREATE OR REPLACE FUNCTION private.is_student_user(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.students s
    WHERE s.id = p_student_id
      AND s.user_id = (SELECT auth.uid())
  );
$$;

-- B1: a atribuição docente só vale enquanto ela própria está vigente E o
-- vínculo do professor com a escola continua ativo.
CREATE OR REPLACE FUNCTION private.is_teacher_of_class(p_class_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.teacher_assignments ta
    JOIN public.school_memberships m
      ON m.user_id = ta.user_id
     AND m.school_id = ta.school_id
     AND m.role = 'teacher'
     AND m.status = 'active'
    WHERE ta.user_id = (SELECT auth.uid())
      AND ta.class_id = p_class_id
      AND ta.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.is_teacher_of_student(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.enrollments e
    JOIN public.teacher_assignments ta
      ON ta.class_id = e.class_id
     AND ta.academic_year_id = e.academic_year_id
     AND ta.school_id = e.school_id
     AND ta.status = 'active'
    JOIN public.school_memberships m
      ON m.user_id = ta.user_id
     AND m.school_id = ta.school_id
     AND m.role = 'teacher'
     AND m.status = 'active'
    WHERE e.student_id = p_student_id
      AND e.status = 'active'
      AND ta.user_id = (SELECT auth.uid())
  );
$$;

-- B1: o vínculo de responsável só vale enquanto o membership 'family' na escola
-- do vínculo continua ativo.
CREATE OR REPLACE FUNCTION private.is_guardian_of_student(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.guardian_student_links gsl
    JOIN public.school_memberships m
      ON m.user_id = gsl.guardian_user_id
     AND m.school_id = gsl.school_id
     AND m.role = 'family'
     AND m.status = 'active'
    WHERE gsl.guardian_user_id = (SELECT auth.uid())
      AND gsl.student_id = p_student_id
      AND gsl.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.can_manage_school(p_school_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.has_any_role_in_school(
    p_school_id,
    ARRAY['admin','coordinator','pedagogy','director']::text[]
  );
$$;

CREATE OR REPLACE FUNCTION private.can_manage_flags(p_school_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.has_any_role_in_school(
    p_school_id,
    ARRAY['admin','coordinator','director']::text[]
  );
$$;

CREATE OR REPLACE FUNCTION private.can_read_student(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    private.is_student_user(p_student_id)
    OR private.is_teacher_of_student(p_student_id)
    OR private.is_guardian_of_student(p_student_id)
    OR EXISTS (
      SELECT 1
      FROM public.students s
      WHERE s.id = p_student_id
        AND private.can_manage_school(s.school_id)
    )
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      WHERE e.student_id = p_student_id
        AND private.can_manage_school(e.school_id)
    );
$$;

CREATE OR REPLACE FUNCTION private.can_read_class(p_class_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.classes c
      WHERE c.id = p_class_id
        AND private.can_manage_school(c.school_id)
    )
    OR private.is_teacher_of_class(p_class_id)
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.students s ON s.id = e.student_id
      WHERE e.class_id = p_class_id
        AND e.status = 'active'
        AND s.user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.guardian_student_links gsl
        ON gsl.student_id = e.student_id
       AND gsl.status = 'active'
      JOIN public.school_memberships m
        ON m.user_id = gsl.guardian_user_id
       AND m.school_id = gsl.school_id
       AND m.role = 'family'
       AND m.status = 'active'
      WHERE e.class_id = p_class_id
        AND e.status = 'active'
        AND gsl.guardian_user_id = (SELECT auth.uid())
    );
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION private.has_any_active_membership() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_member_of_school(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_any_role_in_school(uuid, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_student_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_teacher_of_class(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_teacher_of_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_guardian_of_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_manage_school(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_manage_flags(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_class(uuid) TO authenticated;

-- =========================================================================
-- 3. Policies reapontadas para os helpers de 1 argumento
-- =========================================================================

DROP POLICY schools_select_member ON public.schools;
CREATE POLICY schools_select_member
ON public.schools
FOR SELECT TO authenticated
USING ((SELECT private.is_member_of_school(id)));

DROP POLICY academic_years_select_member ON public.academic_years;
CREATE POLICY academic_years_select_member
ON public.academic_years
FOR SELECT TO authenticated
USING ((SELECT private.is_member_of_school(school_id)));

DROP POLICY memberships_select_self_or_management ON public.school_memberships;
CREATE POLICY memberships_select_self_or_management
ON public.school_memberships
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = user_id
  OR (SELECT private.can_manage_school(school_id))
);

DROP POLICY classes_select_authorized ON public.classes;
CREATE POLICY classes_select_authorized
ON public.classes
FOR SELECT TO authenticated
USING ((SELECT private.can_read_class(id)));

DROP POLICY students_select_authorized ON public.students;
CREATE POLICY students_select_authorized
ON public.students
FOR SELECT TO authenticated
USING ((SELECT private.can_read_student(id)));

DROP POLICY enrollments_select_authorized ON public.enrollments;
CREATE POLICY enrollments_select_authorized
ON public.enrollments
FOR SELECT TO authenticated
USING ((SELECT private.can_read_student(student_id)));

DROP POLICY teacher_assignments_select_self_or_management ON public.teacher_assignments;
CREATE POLICY teacher_assignments_select_self_or_management
ON public.teacher_assignments
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = user_id
  OR (SELECT private.can_manage_school(school_id))
);

DROP POLICY guardian_links_select_authorized ON public.guardian_student_links;
CREATE POLICY guardian_links_select_authorized
ON public.guardian_student_links
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = guardian_user_id
  OR (SELECT private.is_student_user(student_id))
  OR (SELECT private.can_manage_school(school_id))
);

-- L4: o catálogo deixa de ser legível por qualquer sessão autenticada.
DROP POLICY feature_flag_catalog_select_authenticated ON public.feature_flag_catalog;
CREATE POLICY feature_flag_catalog_select_member
ON public.feature_flag_catalog
FOR SELECT TO authenticated
USING ((SELECT private.has_any_active_membership()));

DROP POLICY feature_flag_overrides_select_management ON public.feature_flag_overrides;
CREATE POLICY feature_flag_overrides_select_management
ON public.feature_flag_overrides
FOR SELECT TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags(school_id))
);

DROP POLICY feature_flag_overrides_insert_management ON public.feature_flag_overrides;
CREATE POLICY feature_flag_overrides_insert_management
ON public.feature_flag_overrides
FOR INSERT TO authenticated
WITH CHECK (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND created_by = (SELECT auth.uid())
  AND (SELECT private.can_manage_flags(school_id))
);

DROP POLICY feature_flag_overrides_update_management ON public.feature_flag_overrides;
CREATE POLICY feature_flag_overrides_update_management
ON public.feature_flag_overrides
FOR UPDATE TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags(school_id))
)
WITH CHECK (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags(school_id))
);

DROP POLICY feature_flag_overrides_delete_management ON public.feature_flag_overrides;
CREATE POLICY feature_flag_overrides_delete_management
ON public.feature_flag_overrides
FOR DELETE TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags(school_id))
);

DROP POLICY audit_logs_select_management ON public.audit_logs;
CREATE POLICY audit_logs_select_management
ON public.audit_logs
FOR SELECT TO authenticated
USING (
  school_id IS NOT NULL
  AND (
    SELECT private.has_any_role_in_school(
      school_id,
      ARRAY['admin','coordinator','director']::text[]
    )
  )
);

-- =========================================================================
-- 4. Remoção dos helpers com sujeito arbitrário (A1)
-- =========================================================================

DROP FUNCTION private.is_member_of_school(uuid, uuid);
DROP FUNCTION private.has_any_role_in_school(uuid, uuid, text[]);
DROP FUNCTION private.is_student_user(uuid, uuid);
DROP FUNCTION private.is_teacher_of_class(uuid, uuid);
DROP FUNCTION private.is_teacher_of_student(uuid, uuid);
DROP FUNCTION private.is_guardian_of_student(uuid, uuid);
DROP FUNCTION private.can_manage_school(uuid, uuid);
DROP FUNCTION private.can_manage_flags(uuid, uuid);
DROP FUNCTION private.can_read_student(uuid, uuid);
DROP FUNCTION private.can_read_class(uuid, uuid);

-- =========================================================================
-- 5. Provisionamento de user_profiles (B4)
-- =========================================================================

CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, display_name)
  VALUES (
    NEW.id,
    left(
      btrim(coalesce(
        nullif(btrim(NEW.raw_user_meta_data ->> 'display_name'), ''),
        nullif(btrim(NEW.raw_user_meta_data ->> 'full_name'), ''),
        nullif(split_part(coalesce(NEW.email, ''), '@', 1), ''),
        'Usuário'
      )),
      80
    )
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION private.handle_new_auth_user();

-- Backfill de contas criadas antes desta migration.
INSERT INTO public.user_profiles (user_id, display_name)
SELECT
  u.id,
  left(
    btrim(coalesce(
      nullif(btrim(u.raw_user_meta_data ->> 'display_name'), ''),
      nullif(btrim(u.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
      'Usuário'
    )),
    80
  )
FROM auth.users u
LEFT JOIN public.user_profiles p ON p.user_id = u.id
WHERE p.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- =========================================================================
-- 6. Override de flag com escopo 'user' precisa de vínculo ativo (A2)
-- =========================================================================

CREATE OR REPLACE FUNCTION private.assert_flag_override_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.scope_type = 'user' AND NOT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = NEW.user_id
      AND m.school_id = NEW.school_id
      AND m.status = 'active'
  ) THEN
    -- Mesma mensagem para UUID inexistente e para UUID de outra escola:
    -- não devolve oráculo de existência de conta a quem administra flags.
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'FLAG_OVERRIDE_USER_NOT_IN_SCHOOL';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.assert_flag_override_scope() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER feature_flag_overrides_validate_scope
BEFORE INSERT OR UPDATE OF scope_type, school_id, user_id
ON public.feature_flag_overrides
FOR EACH ROW EXECUTE FUNCTION private.assert_flag_override_scope();

-- =========================================================================
-- 7. Resolver de flags exige vínculo com a turma (M1)
-- =========================================================================

CREATE OR REPLACE FUNCTION public.get_feature_flag(
  p_key text,
  p_school_id uuid,
  p_class_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := (SELECT auth.uid());
  v_flag_id uuid;
  v_default boolean;
  v_override boolean;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'AUTH_REQUIRED';
  END IF;

  IF NOT private.is_member_of_school(p_school_id) THEN
    RAISE EXCEPTION USING MESSAGE = 'FORBIDDEN_SCOPE';
  END IF;

  -- Antes bastava a turma pertencer à escola; qualquer membro lia a flag de
  -- qualquer turma. Agora exige vínculo real com a turma.
  IF p_class_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.classes c
      WHERE c.id = p_class_id
        AND c.school_id = p_school_id
    ) OR NOT private.can_read_class(p_class_id) THEN
      RAISE EXCEPTION USING MESSAGE = 'FORBIDDEN_SCOPE';
    END IF;
  END IF;

  SELECT f.id, f.default_enabled
  INTO v_flag_id, v_default
  FROM public.feature_flag_catalog f
  WHERE f.key = p_key;

  IF v_flag_id IS NULL THEN
    -- Não é erro para o chamador, mas precisa ser visível na operação:
    -- uma chave digitada errada não pode virar "desligado" silencioso.
    RAISE WARNING 'get_feature_flag: chave desconhecida %', p_key;
    RETURN false;
  END IF;

  SELECT o.enabled
  INTO v_override
  FROM public.feature_flag_overrides o
  WHERE o.flag_id = v_flag_id
    AND (
      o.scope_type = 'global'
      OR (o.scope_type = 'school' AND o.school_id = p_school_id)
      OR (
        o.scope_type = 'class'
        AND p_class_id IS NOT NULL
        AND o.school_id = p_school_id
        AND o.class_id = p_class_id
      )
      OR (
        o.scope_type = 'role'
        AND o.school_id = p_school_id
        AND EXISTS (
          SELECT 1
          FROM public.school_memberships m
          WHERE m.user_id = v_user
            AND m.school_id = p_school_id
            AND m.status = 'active'
            AND m.role = o.role
        )
      )
      OR (
        o.scope_type = 'user'
        AND o.school_id = p_school_id
        AND o.user_id = v_user
      )
    )
  ORDER BY
    CASE o.scope_type
      WHEN 'user' THEN 5
      WHEN 'class' THEN 4
      WHEN 'role' THEN 3
      WHEN 'school' THEN 2
      WHEN 'global' THEN 1
      ELSE 0
    END DESC,
    o.priority DESC,
    o.updated_at DESC
  LIMIT 1;

  RETURN COALESCE(v_override, v_default, false);
END;
$$;

REVOKE ALL ON FUNCTION public.get_feature_flag(text, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_feature_flag(text, uuid, uuid) TO authenticated;

-- =========================================================================
-- 8. CHECK de PII do audit passa a ser recursivo e normalizado (M4)
-- =========================================================================

CREATE OR REPLACE FUNCTION private.jsonb_has_forbidden_key(p_data jsonb)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  -- Comparadas após normalização: minúsculas e sem separadores.
  -- 'ip_address', 'IP-Address', 'clientIp' e 'X-Forwarded-For' colidem aqui.
  v_forbidden text[] := ARRAY[
    'ip', 'ipaddress', 'rawip', 'clientip', 'remoteip', 'remoteaddr',
    'xforwardedfor', 'xrealip', 'useragent', 'ua', 'fingerprint',
    'devicefingerprint', 'geolocation', 'latlng'
  ];
  k text;
  v jsonb;
BEGIN
  IF p_data IS NULL THEN
    RETURN false;
  END IF;

  IF jsonb_typeof(p_data) = 'object' THEN
    FOR k, v IN SELECT key, value FROM jsonb_each(p_data) LOOP
      IF regexp_replace(lower(k), '[^a-z0-9]', '', 'g') = ANY (v_forbidden) THEN
        RETURN true;
      END IF;
      IF private.jsonb_has_forbidden_key(v) THEN
        RETURN true;
      END IF;
    END LOOP;
  ELSIF jsonb_typeof(p_data) = 'array' THEN
    FOR v IN SELECT value FROM jsonb_array_elements(p_data) LOOP
      IF private.jsonb_has_forbidden_key(v) THEN
        RETURN true;
      END IF;
    END LOOP;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION private.jsonb_has_forbidden_key(jsonb) FROM PUBLIC, anon, authenticated;

ALTER TABLE public.audit_logs
  DROP CONSTRAINT audit_metadata_no_raw_network_pii;

ALTER TABLE public.audit_logs
  ADD CONSTRAINT audit_metadata_no_raw_network_pii
    CHECK (NOT private.jsonb_has_forbidden_key(metadata)),
  ADD CONSTRAINT audit_diff_no_raw_network_pii
    CHECK (NOT private.jsonb_has_forbidden_key(diff_summary));

-- =========================================================================
-- 9. Auditoria além de feature flags (M5)
-- =========================================================================

CREATE OR REPLACE FUNCTION private.audit_row_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old jsonb := CASE WHEN TG_OP = 'INSERT' THEN '{}'::jsonb ELSE to_jsonb(OLD) END;
  v_new jsonb := CASE WHEN TG_OP = 'DELETE' THEN '{}'::jsonb ELSE to_jsonb(NEW) END;
  v_row jsonb := CASE WHEN TG_OP = 'DELETE' THEN v_old ELSE v_new END;
  -- Apenas colunas de autoridade/estado. Nome, data de nascimento, matrícula e
  -- qualquer outro dado pessoal ficam fora do registro de auditoria.
  v_tracked text[] := ARRAY[
    'status', 'role', 'is_primary', 'is_main_teacher', 'subject_area',
    'school_id', 'class_id', 'academic_year_id', 'user_id',
    'guardian_user_id', 'student_id', 'ended_at', 'verified_at'
  ];
  v_diff jsonb := '{}'::jsonb;
  v_changed text[] := ARRAY[]::text[];
  k text;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    SELECT coalesce(array_agg(e.key ORDER BY e.key), ARRAY[]::text[])
    INTO v_changed
    FROM jsonb_each(v_new) AS e
    WHERE (v_old -> e.key) IS DISTINCT FROM (v_new -> e.key)
      AND e.key <> 'updated_at';
  END IF;

  FOREACH k IN ARRAY v_tracked LOOP
    IF (v_old -> k) IS DISTINCT FROM (v_new -> k) THEN
      v_diff := v_diff || jsonb_build_object(
        k, jsonb_build_object('from', v_old -> k, 'to', v_new -> k)
      );
    END IF;
  END LOOP;

  IF TG_OP = 'UPDATE' AND v_diff = '{}'::jsonb THEN
    -- Mudança sem relevância de autoridade (ex.: só metadata) não vira registro.
    RETURN NEW;
  END IF;

  INSERT INTO public.audit_logs (
    user_id, school_id, action, resource_type, resource_id,
    diff_summary, metadata
  ) VALUES (
    (SELECT auth.uid()),
    (v_row ->> 'school_id')::uuid,
    TG_TABLE_NAME || '_' || lower(TG_OP),
    TG_TABLE_NAME,
    (v_row ->> 'id')::uuid,
    v_diff,
    jsonb_build_object('changed_columns', to_jsonb(v_changed))
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.audit_row_change() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER school_memberships_audit
AFTER INSERT OR UPDATE OR DELETE ON public.school_memberships
FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();

CREATE TRIGGER guardian_student_links_audit
AFTER INSERT OR UPDATE OR DELETE ON public.guardian_student_links
FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();

CREATE TRIGGER teacher_assignments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.teacher_assignments
FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();

CREATE TRIGGER students_audit
AFTER INSERT OR UPDATE OR DELETE ON public.students
FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();

CREATE TRIGGER enrollments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.enrollments
FOR EACH ROW EXECUTE FUNCTION private.audit_row_change();

COMMIT;
