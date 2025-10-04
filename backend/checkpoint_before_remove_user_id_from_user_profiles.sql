-- Checkpoint: Backup user_profiles table before removing user_id column
CREATE TABLE IF NOT EXISTS user_profiles_backup_before_remove_user_id AS
SELECT * FROM user_profiles;

-- You can restore with:
-- DROP TABLE IF EXISTS user_profiles;
-- CREATE TABLE user_profiles AS SELECT * FROM user_profiles_backup_before_remove_user_id; 