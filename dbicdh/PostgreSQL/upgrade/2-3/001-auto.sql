-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/2/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "storage_slot_type" (
  "type_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  "can_request" boolean DEFAULT 't' NOT NULL,
  PRIMARY KEY ("type_id")
);

;
ALTER TABLE storage_request ADD COLUMN type_id uuid NOT NULL;

;
CREATE INDEX storage_request_idx_type_id on storage_request (type_id);

;
ALTER TABLE storage_request ADD CONSTRAINT storage_request_fk_type_id FOREIGN KEY (type_id)
  REFERENCES storage_slot_type (type_id);

;
ALTER TABLE storage_slot ADD COLUMN type_id uuid NOT NULL;

;
CREATE INDEX storage_slot_idx_type_id on storage_slot (type_id);

;
ALTER TABLE storage_slot ADD CONSTRAINT storage_slot_fk_type_id FOREIGN KEY (type_id)
  REFERENCES storage_slot_type (type_id);

;

COMMIT;

