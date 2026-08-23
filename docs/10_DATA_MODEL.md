# 10 — Modelo de Dados Canônico

Este documento define entidades e invariantes. Codex deve transformar em migrations versionadas, sem criar tudo numa única migration gigante.

## Invariantes globais
- UUID interno em entidades operacionais.
- Nome nunca é chave.
- timestamps em UTC.
- school_id e academic_year_id em escopo operacional, direta ou indiretamente com FK comprovável.
- created_at / updated_at.
- actor_user_id em ações administrativas.
- `active`/estado em catálogos, em vez de apagar histórico.
- tabelas sensíveis com RLS.
- service role somente em backend administrativo.

## Organização
### networks
id, name, active

### schools
id, network_id, name, slug, timezone, active

### school_branding
school_id, logo, name_display, theme_config

### academic_years
id, school_id, year, starts_at, ends_at, status

### terms
id, academic_year_id, label, sequence, starts_at, ends_at

### stages
id, school_id, name, grade_min, grade_max

### classes
id, school_id, academic_year_id, stage_id, grade, code, name, active

### subjects
id, code, name, icon_key, active

### class_subjects
class_id, subject_id, teacher_assignment config

## Identidade
### user_profiles
user_id (auth.users), display_name, locale, accessibility prefs

### school_memberships
user_id, school_id, role, status

### students
id, school_id, edugame_id, official_name, social_name, display_name, user_id, status

### enrollments
id, student_id, class_id, academic_year_id, starts_at, ends_at, status

### teacher_assignments
user_id, class_id, subject_id nullable, academic_year_id, permission_level

### guardian_student_links
guardian_user_id, student_id, relationship_label, status, verified_at

### consents
subject_user/student, type, version, granted_at, revoked_at

## Grupos
### student_groups
id, class_id, name, motto, emblem, active

### group_memberships
group_id, student_id, role_key, starts_at, ends_at

## Currículo
### curriculum_frameworks
id, school/network, name, version, source

### curriculum_skills
id, framework_id, subject_id, grade, code, description, term tags

### curriculum_units
id, skill_id, title, description, sequence

## Questões
### questions
id, school_id nullable for network content, subject_id, skill_id, grade, difficulty, bloom_level, kind, statement, hint, solution, image_asset_id, audio_asset_id, status, created_by

### question_options
id, question_id, option_key, text, is_correct, feedback
`is_correct` nunca é concedido em SELECT direto para estudante.

## Quiz
### quizzes
id, school_id, academic_year_id, class_id nullable, title, policy_id, opens_at, closes_at, status, published_at

### quiz_questions
quiz_id, question_id, sequence, points_override nullable

### quiz_sessions
id, quiz_id, student_id, state, started_at, completed_at, score_summary

### question_attempts
id, quiz_session_id, student_id, question_id, attempt_no, chosen_option_id, is_correct, points_award, created_at
unique(session, question, attempt_no)

### skill_events
id, student_id, skill_id, event_type, evidence_type, evidence_id, created_at

### skill_profiles
student_id, skill_id, evidence_count, confidence, last_state, updated_at

### review_queue
id, student_id, skill_id, priority, source_type, source_id, state

## Recursos
### learning_resources
id, subject_id, title, provider, url/storage_path, duration_seconds, summary, transcript, status, curated_by

### resource_skills
resource_id, skill_id

### resource_progress
student_id, resource_id, seconds_watched, percent, completed_at, updated_at

### micro_checks
id, resource_id, skill_id, prompt, status

### micro_check_options
id, micro_check_id, key, text, is_correct, feedback

### micro_check_attempts
student_id, micro_check_id, option_id, is_correct, created_at

## Pontuação
### scoring_rules
id, school_id, academic_year_id, ledger_type, code, title, default_amount, constraints_json, valid_from, valid_to, active

### score_transactions
id, school_id, academic_year_id, ledger_type, student_id nullable, group_id nullable, class_id nullable, amount, rule_id, origin_type, origin_id, reason, subject_id nullable, actor_user_id, source_key, reversal_of, created_at
CHECK: exatamente um target compatível com ledger_type.
UNIQUE: source_key quando não nulo.

### score_balance_snapshots
ledger_type, target_id, period, balance, computed_at

## Elegibilidade
### eligibility_rules
id, school_id, academic_year_id, type, config_json, version, active

### eligibility_results
rule_id, target_type, target_id, period, eligible, reason_codes, computed_at

## Missões
### missions
id, school_id, academic_year_id, scope_type, title, description, starts_at, ends_at, evidence_type, reward_rule, status

### mission_assignments
mission_id, target_type, target_id

### mission_progress
mission_id, target_id, value, state, updated_at

### mission_evidence
mission_id, target_id, submitted_by, storage_ref/text, moderation_state

## Insígnias e recompensas
### badges
id, school_id nullable, code, title, description, icon_asset_id, active

### badge_awards
badge_id, student/group/class target, source, awarded_at

### reward_catalog
id, school_id, type, title, description, active

### unlock_rules
id, item/reward target, condition_type, condition_value, school_id, academic_year_id

### student_unlocks
student_id, unlockable_type, unlockable_id, source, unlocked_at

## Avatar
### body_families
id, code F01-F08, name, config_json

### animal_species
id, catalog_number, name, body_family_id, anatomy_json, educational_profile_json, active

### avatar_items
id, code, category, title, rarity, asset_key, active, moderation_state

### avatar_item_variants
item_id, body_family_id nullable, asset_key, transform_json, compatibility

### student_inventory
student_id, item_id, source, unlocked_at
unique(student,item)

### student_avatars
id, student_id, name, species_id, colors_json, equipped_items_json, background_item_id, effect_item_id, pet_id, is_active, updated_at

## Pet
### pets
id, code, title, base_asset_key, active

### student_pets
student_id, pet_id, display_name, level, xp, appearance_json, animation_state, updated_at

## Jogos
### game_definitions
id, code, title, engine_type, min_players, max_players, supports_solo, supports_live, status

### game_content_sets
id, game_id, subject_id, skill_id, grade, content_json, status, curated_by

### game_rooms
id, school_id, class_id nullable, game_id, host_user_id, join_code, state, config_json, created_at

### game_players
room_id, student_id, joined_at, state

### game_rounds
id, room_id, sequence, content_ref, starts_at, ends_at, state

### game_actions
id, round_id, student_id, action_type, payload_sanitized, received_at, result_json
Não guardar segredo/gabarito no payload ao cliente.

### game_results
room_id, student_id, game_score, xp_award, official_points_award, placement, source_key

## Eventos
### events
id, school_id, academic_year_id, title, description, starts_at, ends_at, location, capacity, audience_json, status

### event_eligibility
event_id, eligibility_rule_id

### event_registrations
event_id, student_id, state, created_at

### special_room_matches
id, event_id, stage_id, participants_json, game_id, winner_class_id, result_json

## Convivência — sensível
### incident_categories
id, school_id, code, title, sensitivity_level

### incidents
id, school_id, academic_year_id, student_id primary subject, category_id, occurred_at, narrative_private, status, created_by

### incident_people
incident_id, person_ref encrypted/private role, relation_type
Nunca expor nomes de terceiros ao estudante.

### restorative_actions
id, incident_id, action_type, description, responsible_user_id, due_at, status

### action_plans
id, school_id, student/class scope, problem, hypothesis, action, owner, due_at, metric, review_state

## Comunicação
### notifications
id, school_id, category, title, body, deep_link, created_at

### notification_recipients
notification_id, user_id, read_at

### notification_preferences
user_id, category, in_app, push

### weekly_family_prompts
id, school_id, grade/class scope, subject_id, prompt, learning_goal, suggested_conversations, week_id, status

## Governança
### audit_logs
id, school_id, actor_user_id, action, entity_type, entity_id, metadata_sanitized, created_at

### import_runs
id, school_id, type, file_hash, started_by, counts_json, status

### import_rows
import_run_id, row_number, source_key, state, error_code

### export_jobs
id, requested_by, scope, filters, status, storage_ref, expires_at

### feature_flags
school_id nullable, key, enabled, config_json

### settings_versions
school_id, academic_year_id nullable, namespace, version, config_json, valid_from

### metric_snapshots
school/class/student scope, metric_key, period, numerator, denominator, value, computed_at

### system_incidents
id, environment, severity, summary, started_at, resolved_at, postmortem_ref
