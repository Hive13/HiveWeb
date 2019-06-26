-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/14/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE members ADD COLUMN alert_credits integer;

;
ALTER TABLE members ADD COLUMN alert_email boolean;

;
ALTER TABLE members ADD COLUMN alert_machine boolean;

;

COMMIT;

