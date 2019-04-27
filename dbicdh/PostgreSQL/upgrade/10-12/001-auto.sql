-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/10/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "purchase" (
  "purchase_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "purchased_at" date DEFAULT CURRENT_DATE NOT NULL,
  PRIMARY KEY ("purchase_id")
);
CREATE INDEX "purchase_idx_member_id" on "purchase" ("member_id");

;
CREATE TABLE "purchase_soda_type" (
  "purchase_id" uuid NOT NULL,
  "soda_type_id" uuid NOT NULL,
  "soda_quantity" integer NOT NULL,
  PRIMARY KEY ("purchase_id", "soda_type_id")
);
CREATE INDEX "purchase_soda_type_idx_purchase_id" on "purchase_soda_type" ("purchase_id");
CREATE INDEX "purchase_soda_type_idx_soda_type_id" on "purchase_soda_type" ("soda_type_id");

;
ALTER TABLE "purchase" ADD CONSTRAINT "purchase_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "purchase_soda_type" ADD CONSTRAINT "purchase_soda_type_fk_purchase_id" FOREIGN KEY ("purchase_id")
  REFERENCES "purchase" ("purchase_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "purchase_soda_type" ADD CONSTRAINT "purchase_soda_type_fk_soda_type_id" FOREIGN KEY ("soda_type_id")
  REFERENCES "soda_type" ("soda_type_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;

COMMIT;

