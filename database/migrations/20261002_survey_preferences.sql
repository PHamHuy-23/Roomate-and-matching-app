-- PostgreSQL / Supabase: persist the four previously UI-only survey fields.
-- Additive and safe to rerun; no records are deleted or assigned invented defaults.
BEGIN;

ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS move_in_date DATE;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS room_type VARCHAR(10);
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS work_schedule VARCHAR(10);
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS personal_value VARCHAR(10);

-- NOT VALID preserves pre-existing rows; new/updated rows are still checked.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'user_preferences'::regclass
                   AND conname = 'user_preferences_room_type_check') THEN
        ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_room_type_check
            CHECK (room_type IN ('PRIVATE', 'SHARED')) NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'user_preferences'::regclass
                   AND conname = 'user_preferences_work_schedule_check') THEN
        ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_work_schedule_check
            CHECK (work_schedule IN ('DAY', 'NIGHT')) NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'user_preferences'::regclass
                   AND conname = 'user_preferences_personal_value_check') THEN
        ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_personal_value_check
            CHECK (personal_value IN ('PRIVACY', 'SCHEDULE', 'CLEAN')) NOT VALID;
    END IF;
END $$;

COMMIT;
