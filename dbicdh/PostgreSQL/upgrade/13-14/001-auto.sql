-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/13/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE action ALTER COLUMN priority TYPE integer;

;
ALTER TABLE application ALTER COLUMN created_at TYPE timestamp with time zone;

;
ALTER TABLE application ALTER COLUMN created_at SET DEFAULT current_timestamp;

;
ALTER TABLE application ALTER COLUMN updated_at TYPE timestamp with time zone;

;
ALTER TABLE application ALTER COLUMN updated_at SET DEFAULT current_timestamp;

;
ALTER TABLE members ALTER COLUMN created_at TYPE timestamp with time zone;

;
ALTER TABLE members ALTER COLUMN created_at SET DEFAULT current_timestamp;

;
ALTER TABLE members ALTER COLUMN updated_at TYPE timestamp with time zone;

;
ALTER TABLE members ALTER COLUMN updated_at SET DEFAULT current_timestamp;

;
ALTER TABLE reset_token ALTER COLUMN created_at TYPE timestamp with time zone;

;
ALTER TABLE reset_token ALTER COLUMN created_at SET DEFAULT current_timestamp;

;

COMMIT;

