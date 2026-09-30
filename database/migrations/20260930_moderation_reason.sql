-- Additive migration: preserves existing room posts and demo data.
ALTER TABLE room_posts ADD COLUMN IF NOT EXISTS moderation_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS search_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS budget_min DOUBLE PRECISION;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS budget_max DOUBLE PRECISION;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS target_gender VARCHAR(10);
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS top_priority VARCHAR(10);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS evidence_url VARCHAR(1000);
CREATE TABLE IF NOT EXISTS user_saved_posts (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, post_id)
);
