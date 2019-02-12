-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "ipn_message" (
  "ipn_message_id" uuid NOT NULL,
  "member_id" uuid,
  "received_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "txn_id" character varying NOT NULL,
  "payer_email" character varying NOT NULL,
  "raw" text NOT NULL,
  PRIMARY KEY ("ipn_message_id")
);
CREATE INDEX "ipn_message_idx_member_id" on "ipn_message" ("member_id");

;
CREATE TABLE "payment" (
  "payment_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "ipn_message_id" uuid NOT NULL,
  "payment_date" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("payment_id")
);
CREATE INDEX "payment_idx_ipn_message_id" on "payment" ("ipn_message_id");
CREATE INDEX "payment_idx_member_id" on "payment" ("member_id");

;
ALTER TABLE "ipn_message" ADD CONSTRAINT "ipn_message_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_ipn_message_id" FOREIGN KEY ("ipn_message_id")
  REFERENCES "ipn_message" ("ipn_message_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE audit_log ALTER COLUMN changing_member_id DROP NOT NULL;

;
ALTER TABLE members ADD COLUMN linked_member_id uuid;

;
ALTER TABLE members ADD CONSTRAINT members_fk_member_id FOREIGN KEY (member_id)
  REFERENCES members (linked_member_id) DEFERRABLE;

;

COMMIT;

