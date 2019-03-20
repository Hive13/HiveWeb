-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/6/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE application ADD COLUMN helper character varying;

;

COMMIT;

