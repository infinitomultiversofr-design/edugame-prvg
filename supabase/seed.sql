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

-- DEV/TEST ONLY.
-- Não mover este arquivo para migrations/.

INSERT INTO public.schools (
  id, name, short_name, slug
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  'EMEFTI Paulo Roberto Vieira Gomes',
  'PRVG',
  'prvg'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.academic_years (
  id, school_id, year, start_date, end_date, is_active
) VALUES (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  2026,
  '2026-02-01',
  '2026-12-15',
  true
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.classes (
  id, school_id, academic_year_id, name, grade, code
) VALUES (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '6º A',
  '6º ano',
  '6A'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.feature_flag_catalog (
  key, default_enabled, description
) VALUES
  ('avatar_3d', false, 'Habilita visualização imersiva/3D de Avatar'),
  ('arena_multiplayer', false, 'Habilita Arena multiplayer')
ON CONFLICT (key) DO NOTHING;
