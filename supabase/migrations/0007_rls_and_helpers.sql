/*
 * EDUGAME — M0 FOUNDATION
 *
 * INVARIANTES DE IDENTIDADE E AUTORIDADE
 * 1. Nenhuma identidade operacional usa serial/bigserial.
 *    PKs operacionais usam UUID; relações puramente associativas podem usar chaves compostas.
 * 2. Códigos humanos (turma, habilidade, ID EduGame etc.) não substituem FKs.
 * 3. O navegador nunca é autoridade para pontuação, acerto, desbloqueio ou identidade de outro usuário.
 * 4. Operações sensíveis posteriores devem ser server-authoritative, idempotentes e auditáveis.
 * 5. Entidades históricas são inativadas/arquivadas; não dependemos de DELETE CASCADE para “limpeza”.
 */

BEGIN;

-- -------------------------
-- PRIVATE AUTHZ HELPERS
-- -------------------------

CREATE OR REPLACE FUNCTION private.is_member_of_school(
  p_user_id uuid,
  p_school_id uuid
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
    WHERE m.user_id = p_user_id
      AND m.school_id = p_school_id
      AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.has_any_role_in_school(
  p_user_id uuid,
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
    WHERE m.user_id = p_user_id
      AND m.school_id = p_school_id
      AND m.status = 'active'
      AND m.role = ANY (p_roles)
  );
$$;

CREATE OR REPLACE FUNCTION private.is_student_user(
  p_user_id uuid,
  p_student_id uuid
)
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
      AND s.user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION private.is_teacher_of_class(
  p_user_id uuid,
  p_class_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.teacher_assignments ta
    WHERE ta.user_id = p_user_id
      AND ta.class_id = p_class_id
  );
$$;

CREATE OR REPLACE FUNCTION private.is_teacher_of_student(
  p_user_id uuid,
  p_student_id uuid
)
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
    WHERE e.student_id = p_student_id
      AND e.status = 'active'
      AND ta.user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION private.is_guardian_of_student(
  p_user_id uuid,
  p_student_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.guardian_student_links gsl
    WHERE gsl.guardian_user_id = p_user_id
      AND gsl.student_id = p_student_id
      AND gsl.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.can_manage_school(
  p_user_id uuid,
  p_school_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.has_any_role_in_school(
    p_user_id,
    p_school_id,
    ARRAY['admin','coordinator','pedagogy','director']::text[]
  );
$$;

CREATE OR REPLACE FUNCTION private.can_manage_flags(
  p_user_id uuid,
  p_school_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.has_any_role_in_school(
    p_user_id,
    p_school_id,
    ARRAY['admin','coordinator','director']::text[]
  );
$$;

CREATE OR REPLACE FUNCTION private.can_read_student(
  p_user_id uuid,
  p_student_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    private.is_student_user(p_user_id, p_student_id)
    OR private.is_teacher_of_student(p_user_id, p_student_id)
    OR private.is_guardian_of_student(p_user_id, p_student_id)
    OR EXISTS (
      SELECT 1
      FROM public.students s
      WHERE s.id = p_student_id
        AND private.can_manage_school(p_user_id, s.school_id)
    )
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      WHERE e.student_id = p_student_id
        AND private.can_manage_school(p_user_id, e.school_id)
    );
$$;

CREATE OR REPLACE FUNCTION private.can_read_class(
  p_user_id uuid,
  p_class_id uuid
)
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
        AND private.can_manage_school(p_user_id, c.school_id)
    )
    OR private.is_teacher_of_class(p_user_id, p_class_id)
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.students s ON s.id = e.student_id
      WHERE e.class_id = p_class_id
        AND e.status = 'active'
        AND s.user_id = p_user_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.guardian_student_links gsl
        ON gsl.student_id = e.student_id
       AND gsl.status = 'active'
      WHERE e.class_id = p_class_id
        AND e.status = 'active'
        AND gsl.guardian_user_id = p_user_id
    );
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;

GRANT USAGE ON SCHEMA private TO authenticated;

GRANT EXECUTE ON FUNCTION private.is_member_of_school(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_any_role_in_school(uuid, uuid, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_student_user(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_teacher_of_class(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_teacher_of_student(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_guardian_of_student(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_manage_school(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_manage_flags(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_student(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_class(uuid, uuid) TO authenticated;

-- -------------------------
-- FEATURE FLAG RESOLVER
-- -------------------------

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
  v_user uuid := auth.uid();
  v_flag_id uuid;
  v_default boolean;
  v_override boolean;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = 'AUTH_REQUIRED';
  END IF;

  IF NOT private.is_member_of_school(v_user, p_school_id) THEN
    RAISE EXCEPTION USING MESSAGE = 'FORBIDDEN_SCOPE';
  END IF;

  IF p_class_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.classes c
    WHERE c.id = p_class_id
      AND c.school_id = p_school_id
  ) THEN
    RAISE EXCEPTION USING MESSAGE = 'FORBIDDEN_SCOPE';
  END IF;

  SELECT f.id, f.default_enabled
  INTO v_flag_id, v_default
  FROM public.feature_flag_catalog f
  WHERE f.key = p_key;

  IF v_flag_id IS NULL THEN
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

REVOKE ALL ON FUNCTION public.get_feature_flag(text, uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_feature_flag(text, uuid, uuid)
  TO authenticated;

-- -------------------------
-- RLS ENABLEMENT
-- -------------------------

ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardian_student_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flag_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flag_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- -------------------------
-- SELECT POLICIES
-- -------------------------

CREATE POLICY schools_select_member
ON public.schools
FOR SELECT TO authenticated
USING ((SELECT private.is_member_of_school((SELECT auth.uid()), id)));

CREATE POLICY academic_years_select_member
ON public.academic_years
FOR SELECT TO authenticated
USING ((SELECT private.is_member_of_school((SELECT auth.uid()), school_id)));

CREATE POLICY user_profiles_select_self
ON public.user_profiles
FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY user_profiles_update_self
ON public.user_profiles
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY memberships_select_self_or_management
ON public.school_memberships
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = user_id
  OR (SELECT private.can_manage_school((SELECT auth.uid()), school_id))
);

CREATE POLICY classes_select_authorized
ON public.classes
FOR SELECT TO authenticated
USING ((SELECT private.can_read_class((SELECT auth.uid()), id)));

CREATE POLICY students_select_authorized
ON public.students
FOR SELECT TO authenticated
USING ((SELECT private.can_read_student((SELECT auth.uid()), id)));

CREATE POLICY enrollments_select_authorized
ON public.enrollments
FOR SELECT TO authenticated
USING ((SELECT private.can_read_student((SELECT auth.uid()), student_id)));

CREATE POLICY teacher_assignments_select_self_or_management
ON public.teacher_assignments
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = user_id
  OR (SELECT private.can_manage_school((SELECT auth.uid()), school_id))
);

CREATE POLICY guardian_links_select_authorized
ON public.guardian_student_links
FOR SELECT TO authenticated
USING (
  (SELECT auth.uid()) = guardian_user_id
  OR (SELECT private.is_student_user((SELECT auth.uid()), student_id))
  OR (SELECT private.can_manage_school((SELECT auth.uid()), school_id))
);

CREATE POLICY feature_flag_catalog_select_authenticated
ON public.feature_flag_catalog
FOR SELECT TO authenticated
USING (true);

CREATE POLICY feature_flag_overrides_select_management
ON public.feature_flag_overrides
FOR SELECT TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags((SELECT auth.uid()), school_id))
);

CREATE POLICY audit_logs_select_management
ON public.audit_logs
FOR SELECT TO authenticated
USING (
  school_id IS NOT NULL
  AND (
    SELECT private.has_any_role_in_school(
      (SELECT auth.uid()),
      school_id,
      ARRAY['admin','coordinator','director']::text[]
    )
  )
);

-- -------------------------
-- FEATURE FLAG WRITE POLICIES
-- Global overrides remain service-role/admin-backend only.
-- -------------------------

CREATE POLICY feature_flag_overrides_insert_management
ON public.feature_flag_overrides
FOR INSERT TO authenticated
WITH CHECK (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND created_by = (SELECT auth.uid())
  AND (SELECT private.can_manage_flags((SELECT auth.uid()), school_id))
);

CREATE POLICY feature_flag_overrides_update_management
ON public.feature_flag_overrides
FOR UPDATE TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags((SELECT auth.uid()), school_id))
)
WITH CHECK (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags((SELECT auth.uid()), school_id))
);

CREATE POLICY feature_flag_overrides_delete_management
ON public.feature_flag_overrides
FOR DELETE TO authenticated
USING (
  scope_type <> 'global'
  AND school_id IS NOT NULL
  AND (SELECT private.can_manage_flags((SELECT auth.uid()), school_id))
);

-- -------------------------
-- GRANTS
-- -------------------------

REVOKE ALL ON TABLE public.schools FROM anon, authenticated;
REVOKE ALL ON TABLE public.academic_years FROM anon, authenticated;
REVOKE ALL ON TABLE public.user_profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.school_memberships FROM anon, authenticated;
REVOKE ALL ON TABLE public.classes FROM anon, authenticated;
REVOKE ALL ON TABLE public.students FROM anon, authenticated;
REVOKE ALL ON TABLE public.enrollments FROM anon, authenticated;
REVOKE ALL ON TABLE public.teacher_assignments FROM anon, authenticated;
REVOKE ALL ON TABLE public.guardian_student_links FROM anon, authenticated;
REVOKE ALL ON TABLE public.feature_flag_catalog FROM anon, authenticated;
REVOKE ALL ON TABLE public.feature_flag_overrides FROM anon, authenticated;
REVOKE ALL ON TABLE public.audit_logs FROM anon, authenticated;

GRANT SELECT ON public.schools TO authenticated;
GRANT SELECT ON public.academic_years TO authenticated;
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT UPDATE (display_name, avatar_url, preferences)
  ON public.user_profiles TO authenticated;

GRANT SELECT ON public.school_memberships TO authenticated;
GRANT SELECT ON public.classes TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.enrollments TO authenticated;
GRANT SELECT ON public.teacher_assignments TO authenticated;
GRANT SELECT ON public.guardian_student_links TO authenticated;

GRANT SELECT ON public.feature_flag_catalog TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.feature_flag_overrides TO authenticated;

GRANT SELECT ON public.audit_logs TO authenticated;

COMMIT;
