/*
 * SHIM LOCAL — NÃO É MIGRATION.
 *
 * Recria o mínimo do ambiente Supabase (roles, schema auth, auth.uid()) para
 * que as migrations e a suíte pgTAP possam ser validadas em um PostgreSQL puro,
 * sem stack Supabase e sem rede.
 *
 * NUNCA aplicar em um projeto Supabase: lá esses objetos já existem e são
 * gerenciados pela plataforma.
 *
 * Uso:
 *   createdb edugame
 *   psql -d edugame -f scripts/_local_supabase_shim.sql
 *   psql -d edugame -f supabase/migrations/0001_extensions.sql   # ... até 0008
 *   pg_prove -d edugame supabase/tests/
 */

-- Roles são objetos do cluster, não do banco: recriar o banco não os apaga.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN BYPASSRLS;
  END IF;
END;
$$;

GRANT anon, authenticated, service_role TO CURRENT_USER;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE SCHEMA IF NOT EXISTS auth;

GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

CREATE TABLE auth.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE,
  raw_user_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;

GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated, service_role;
