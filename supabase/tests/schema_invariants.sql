BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT extensions.plan(8);

SELECT extensions.has_table('public', 'schools', 'schools existe');
SELECT extensions.has_table('public', 'students', 'students existe');
SELECT extensions.has_table('public', 'classes', 'classes existe');
SELECT extensions.has_table('public', 'enrollments', 'enrollments existe');
SELECT extensions.has_column('public', 'students', 'edugame_id', 'students.edugame_id existe');
SELECT extensions.has_column('public', 'students', 'user_id', 'students.user_id existe');
SELECT extensions.has_table('public', 'feature_flag_overrides', 'feature flag overrides existe');
SELECT extensions.has_table('public', 'audit_logs', 'audit_logs existe');

SELECT * FROM extensions.finish();
ROLLBACK;
