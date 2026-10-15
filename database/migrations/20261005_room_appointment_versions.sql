-- PostgreSQL / Supabase: optimistic locking for room moderation and appointments.
-- Stop ALL backend instances before running; do not reset existing non-null versions.
BEGIN;

ALTER TABLE room_posts ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
UPDATE room_posts SET version = 0 WHERE version IS NULL;
ALTER TABLE room_posts ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE room_posts ALTER COLUMN version SET NOT NULL;

ALTER TABLE viewing_appointments ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
UPDATE viewing_appointments SET version = 0 WHERE version IS NULL;
ALTER TABLE viewing_appointments ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE viewing_appointments ALTER COLUMN version SET NOT NULL;

COMMIT;
