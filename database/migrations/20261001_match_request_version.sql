-- PostgreSQL / Supabase: upgrade an existing database without resetting data.
-- Stop the backend while applying this migration, then restart it after COMMIT.
-- Keep existing non-null versions: resetting them would break optimistic locking.
BEGIN;

ALTER TABLE match_requests ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
UPDATE match_requests SET version = 0 WHERE version IS NULL;
ALTER TABLE match_requests ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE match_requests ALTER COLUMN version SET NOT NULL;

COMMIT;
