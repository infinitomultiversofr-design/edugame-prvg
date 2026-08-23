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

CREATE TABLE public.schools (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(btrim(name)) BETWEEN 2 AND 160),
  short_name text,
  slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  timezone text NOT NULL DEFAULT 'America/Sao_Paulo',
  address jsonb NOT NULL DEFAULT '{}'::jsonb,
  contact jsonb NOT NULL DEFAULT '{}'::jsonb,
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.academic_years (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  year integer NOT NULL CHECK (year BETWEEN 2000 AND 2200),
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  term_structure jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT academic_year_dates_valid CHECK (start_date <= end_date),
  CONSTRAINT academic_year_school_year_unique UNIQUE (school_id, year),
  CONSTRAINT academic_year_id_school_unique UNIQUE (id, school_id)
);

CREATE INDEX academic_years_school_idx
  ON public.academic_years(school_id);

CREATE TRIGGER schools_set_updated_at
BEFORE UPDATE ON public.schools
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER academic_years_set_updated_at
BEFORE UPDATE ON public.academic_years
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

COMMIT;
