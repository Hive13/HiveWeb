-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/5/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE members ALTER COLUMN email SET NOT NULL;

;
ALTER TABLE members ALTER COLUMN encrypted_password SET NOT NULL;

;
ALTER TABLE members ALTER COLUMN vend_credits SET NOT NULL;

;
ALTER TABLE members ALTER COLUMN vend_credits SET DEFAULT 0;

;
ALTER TABLE members ALTER COLUMN vend_total SET NOT NULL;

;
ALTER TABLE members ALTER COLUMN vend_total SET DEFAULT 0;

;

COMMIT;

