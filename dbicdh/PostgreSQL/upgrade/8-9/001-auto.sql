-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/8/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "log" (
  "log_id" uuid NOT NULL,
  "create_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "type" character varying NOT NULL,
  "message" text NOT NULL,
  PRIMARY KEY ("log_id")
);

;

COMMIT;

