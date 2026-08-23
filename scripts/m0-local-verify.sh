#!/usr/bin/env bash
#
# Validação local do M0-A sem stack Supabase.
#
# Aplica o shim (roles, schema auth, auth.uid()), as migrations 0001-0008 e roda
# a suíte pgTAP inteira em um PostgreSQL comum. Serve para iterar em migrations
# e testes antes de gastar um projeto Supabase — NÃO substitui o Gate, que
# exige Auth real via scripts/m0-gate.mjs.
#
# Requisitos: psql, pg_prove (perl TAP::Parser::SourceHandler::pgTAP) e a
# extensão pgtap disponível no servidor.
#
# Uso:
#   PGHOST=/var/run/postgresql PGUSER=postgres ./scripts/m0-local-verify.sh
#   PGDATABASE=edugame_m0 ./scripts/m0-local-verify.sh
#
set -euo pipefail

DB="${PGDATABASE:-edugame_m0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# PGDATABASE apontaria o psql para um banco que estamos prestes a recriar.
unset PGDATABASE

echo "▶ Recriando o banco $DB"
psql -q -c "DROP DATABASE IF EXISTS $DB;" -c "CREATE DATABASE $DB;"

echo "▶ Aplicando o shim do ambiente Supabase"
psql -q -d "$DB" -v ON_ERROR_STOP=1 -f "$ROOT/scripts/_local_supabase_shim.sql"

echo "▶ Aplicando migrations"
for f in "$ROOT"/supabase/migrations/*.sql; do
  printf '   %-46s' "$(basename "$f")"
  psql -q -d "$DB" -v ON_ERROR_STOP=1 -f "$f"
  echo 'ok'
done

echo "▶ Suíte pgTAP"
cd "$ROOT/supabase"
pg_prove -d "$DB" tests/*.sql

echo
echo "✔ Migrations e suíte pgTAP validadas em $DB."
echo "  Falta o Gate com Auth real: scripts/m0-gate.mjs contra Supabase dev/staging isolado."
