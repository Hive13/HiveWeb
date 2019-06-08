-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/12/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE item ADD COLUMN scale integer DEFAULT -1 NOT NULL;

;
ALTER TABLE item ADD COLUMN unit character varying DEFAULT CHR(176) || 'F' NOT NULL;

;

COMMIT;

