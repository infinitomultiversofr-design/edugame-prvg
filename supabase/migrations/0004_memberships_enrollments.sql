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

CREATE TABLE public.school_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  role text NOT NULL CHECK (
    role IN ('student', 'teacher', 'family', 'admin', 'coordinator', 'pedagogy', 'director')
  ),
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'suspended')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT school_membership_unique_role UNIQUE (user_id, school_id, role),
  CONSTRAINT school_membership_end_valid CHECK (ended_at IS NULL OR ended_at >= joined_at)
);

CREATE TABLE public.classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL,
  academic_year_id uuid NOT NULL,
  name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 120),
  grade text NOT NULL CHECK (length(btrim(grade)) BETWEEN 1 AND 40),
  code text NOT NULL CHECK (length(btrim(code)) BETWEEN 1 AND 40),
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT classes_school_fk
    FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT,

  CONSTRAINT classes_year_same_school_fk
    FOREIGN KEY (academic_year_id, school_id)
    REFERENCES public.academic_years(id, school_id) ON DELETE RESTRICT,

  CONSTRAINT classes_school_year_code_unique UNIQUE (school_id, academic_year_id, code),
  CONSTRAINT classes_id_school_unique UNIQUE (id, school_id),
  CONSTRAINT classes_id_school_year_unique UNIQUE (id, school_id, academic_year_id)
);

-- school_id + academic_year_id são redundâncias INTENCIONAIS:
-- elas permitem FKs compostas que impedem turma/ano/escola incompatíveis.
CREATE TABLE public.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL,
  class_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'transferred', 'inactive', 'graduated')),
  enrolled_at date NOT NULL DEFAULT current_date,
  ended_at date,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT enrollment_class_scope_fk
    FOREIGN KEY (class_id, school_id, academic_year_id)
    REFERENCES public.classes(id, school_id, academic_year_id) ON DELETE RESTRICT,

  CONSTRAINT enrollment_dates_valid CHECK (ended_at IS NULL OR ended_at >= enrolled_at)
);

-- Uma matrícula-base ativa por ano letivo. Ao transferir, a anterior deve mudar de status.
CREATE UNIQUE INDEX enrollments_one_active_per_year_idx
  ON public.enrollments(student_id, academic_year_id)
  WHERE status = 'active';

CREATE INDEX enrollments_student_idx ON public.enrollments(student_id);
CREATE INDEX enrollments_class_idx ON public.enrollments(class_id);
CREATE INDEX enrollments_school_year_idx
  ON public.enrollments(school_id, academic_year_id);

CREATE TABLE public.teacher_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL,
  class_id uuid NOT NULL,
  subject_area text,
  is_main_teacher boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT teacher_assignment_class_scope_fk
    FOREIGN KEY (class_id, school_id, academic_year_id)
    REFERENCES public.classes(id, school_id, academic_year_id) ON DELETE RESTRICT,

  CONSTRAINT teacher_assignment_unique UNIQUE (user_id, class_id, subject_area)
);

CREATE INDEX teacher_assignments_user_idx
  ON public.teacher_assignments(user_id);
CREATE INDEX teacher_assignments_class_idx
  ON public.teacher_assignments(class_id);

CREATE TABLE public.guardian_student_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  relationship_type text,
  is_primary boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'inactive', 'revoked')),
  verified_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT guardian_student_unique UNIQUE (guardian_user_id, student_id)
);

CREATE INDEX guardian_links_guardian_idx
  ON public.guardian_student_links(guardian_user_id);
CREATE INDEX guardian_links_student_idx
  ON public.guardian_student_links(student_id);
CREATE INDEX guardian_links_school_idx
  ON public.guardian_student_links(school_id);

CREATE OR REPLACE FUNCTION private.assert_teacher_membership()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = NEW.user_id
      AND m.school_id = NEW.school_id
      AND m.role = 'teacher'
      AND m.status = 'active'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'TEACHER_MEMBERSHIP_REQUIRED';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.assert_guardian_membership()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.school_memberships m
    WHERE m.user_id = NEW.guardian_user_id
      AND m.school_id = NEW.school_id
      AND m.role = 'family'
      AND m.status = 'active'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'FAMILY_MEMBERSHIP_REQUIRED';
  END IF;

  -- O vínculo precisa apontar para a escola atual do registro do estudante
  -- ou para uma escola em que exista matrícula histórica/ativa.
  IF NOT EXISTS (
    SELECT 1
    FROM public.students s
    WHERE s.id = NEW.student_id
      AND (
        s.school_id = NEW.school_id
        OR EXISTS (
          SELECT 1
          FROM public.enrollments e
          WHERE e.student_id = s.id
            AND e.school_id = NEW.school_id
        )
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'GUARDIAN_STUDENT_SCHOOL_MISMATCH';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.assert_teacher_membership() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.assert_guardian_membership() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER teacher_assignments_validate_membership
BEFORE INSERT OR UPDATE OF user_id, school_id
ON public.teacher_assignments
FOR EACH ROW EXECUTE FUNCTION private.assert_teacher_membership();

CREATE TRIGGER guardian_links_validate_membership
BEFORE INSERT OR UPDATE OF guardian_user_id, student_id, school_id
ON public.guardian_student_links
FOR EACH ROW EXECUTE FUNCTION private.assert_guardian_membership();

CREATE TRIGGER school_memberships_set_updated_at
BEFORE UPDATE ON public.school_memberships
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER classes_set_updated_at
BEFORE UPDATE ON public.classes
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER enrollments_set_updated_at
BEFORE UPDATE ON public.enrollments
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER teacher_assignments_set_updated_at
BEFORE UPDATE ON public.teacher_assignments
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

COMMIT;
