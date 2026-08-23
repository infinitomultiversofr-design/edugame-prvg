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

CREATE TABLE public.feature_flag_catalog (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE CHECK (key ~ '^[a-z][a-z0-9_]{2,63}$'),
  default_enabled boolean NOT NULL DEFAULT false,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.feature_flag_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id uuid NOT NULL REFERENCES public.feature_flag_catalog(id) ON DELETE CASCADE,

  scope_type text NOT NULL CHECK (
    scope_type IN ('global', 'school', 'class', 'role', 'user')
  ),

  school_id uuid REFERENCES public.schools(id) ON DELETE RESTRICT,
  class_id uuid,
  role text CHECK (
    role IS NULL OR role IN ('student', 'teacher', 'family', 'admin', 'coordinator', 'pedagogy', 'director')
  ),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,

  enabled boolean NOT NULL,
  priority smallint NOT NULL DEFAULT 0,
  reason text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT feature_flag_override_scope_shape CHECK (
    (scope_type = 'global' AND school_id IS NULL AND class_id IS NULL AND role IS NULL AND user_id IS NULL)
    OR
    (scope_type = 'school' AND school_id IS NOT NULL AND class_id IS NULL AND role IS NULL AND user_id IS NULL)
    OR
    (scope_type = 'class' AND school_id IS NOT NULL AND class_id IS NOT NULL AND role IS NULL AND user_id IS NULL)
    OR
    (scope_type = 'role' AND school_id IS NOT NULL AND class_id IS NULL AND role IS NOT NULL AND user_id IS NULL)
    OR
    (scope_type = 'user' AND school_id IS NOT NULL AND class_id IS NULL AND role IS NULL AND user_id IS NOT NULL)
  ),

  CONSTRAINT feature_flag_override_class_scope_fk
    FOREIGN KEY (class_id, school_id)
    REFERENCES public.classes(id, school_id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX feature_flag_override_global_uq
  ON public.feature_flag_overrides(flag_id)
  WHERE scope_type = 'global';

CREATE UNIQUE INDEX feature_flag_override_school_uq
  ON public.feature_flag_overrides(flag_id, school_id)
  WHERE scope_type = 'school';

CREATE UNIQUE INDEX feature_flag_override_class_uq
  ON public.feature_flag_overrides(flag_id, class_id)
  WHERE scope_type = 'class';

CREATE UNIQUE INDEX feature_flag_override_role_uq
  ON public.feature_flag_overrides(flag_id, school_id, role)
  WHERE scope_type = 'role';

CREATE UNIQUE INDEX feature_flag_override_user_uq
  ON public.feature_flag_overrides(flag_id, school_id, user_id)
  WHERE scope_type = 'user';

CREATE INDEX feature_flag_overrides_school_idx
  ON public.feature_flag_overrides(school_id);
CREATE INDEX feature_flag_overrides_class_idx
  ON public.feature_flag_overrides(class_id);
CREATE INDEX feature_flag_overrides_user_idx
  ON public.feature_flag_overrides(user_id);

CREATE TRIGGER feature_flag_catalog_set_updated_at
BEFORE UPDATE ON public.feature_flag_catalog
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER feature_flag_overrides_set_updated_at
BEFORE UPDATE ON public.feature_flag_overrides
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

COMMIT;
