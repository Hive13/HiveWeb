-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/10/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE storage_slot ADD COLUMN expire_date timestamp with time zone;

;

COMMIT;

