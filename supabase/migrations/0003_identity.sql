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

-- Perfil de autenticação. Se a conta Auth for removida, este perfil pode ser eliminado;
-- a identidade escolar histórica do estudante permanece em public.students.
CREATE TABLE public.user_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL CHECK (length(btrim(display_name)) BETWEEN 1 AND 80),
  avatar_url text,
  preferences jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identificador humano estável e GLOBALMENTE único para login/uso escolar.
  -- O gerador administrativo deve incluir namespace suficiente para impedir colisão.
  edugame_id text NOT NULL UNIQUE CHECK (length(btrim(edugame_id)) BETWEEN 4 AND 64),

  -- O login pode ser removido/rotacionado sem apagar o registro escolar.
  user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Escola atual/de referência. Matrículas históricas ficam em enrollments.
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,

  official_name text NOT NULL CHECK (length(btrim(official_name)) BETWEEN 1 AND 160),
  social_name text,
  display_name text NOT NULL CHECK (length(btrim(display_name)) BETWEEN 1 AND 80),
  enrollment_number text,
  birth_date date,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'transferred', 'graduated', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX students_school_idx ON public.students(school_id);
CREATE INDEX students_user_idx ON public.students(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX students_edugame_id_trgm_idx
  ON public.students USING gin (edugame_id extensions.gin_trgm_ops);
CREATE INDEX students_display_name_trgm_idx
  ON public.students USING gin (display_name extensions.gin_trgm_ops);

CREATE TRIGGER user_profiles_set_updated_at
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER students_set_updated_at
BEFORE UPDATE ON public.students
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

COMMIT;
