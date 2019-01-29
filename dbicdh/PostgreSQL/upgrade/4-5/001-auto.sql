-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "payment" (
  "payment_id" uuid NOT NULL,
  "payment_type_id" uuid NOT NULL,
  "member_id" uuid,
  "payment_date" timestamp with time zone NOT NULL,
  "processed_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "payment_currency" character varying NOT NULL,
  "payment_amount" numeric NOT NULL,
  "paypal_txn_id" character varying NOT NULL,
  "payer_email" character varying NOT NULL,
  "raw" text NOT NULL,
  PRIMARY KEY ("payment_id")
);
CREATE INDEX "payment_idx_member_id" on "payment" ("member_id");
CREATE INDEX "payment_idx_payment_type_id" on "payment" ("payment_type_id");

;
CREATE TABLE "payment_type" (
  "payment_type_id" uuid NOT NULL,
  "name" uuid,
  PRIMARY KEY ("payment_type_id")
);

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_payment_type_id" FOREIGN KEY ("payment_type_id")
  REFERENCES "payment_type" ("payment_type_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;

COMMIT;

