-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "ipn_message" (
  "ipn_message_id" uuid NOT NULL,
  "member_id" uuid,
  "received_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "txn_id" character varying,
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
CREATE TABLE "survey" (
  "survey_id" uuid NOT NULL,
  "title" character varying,
  PRIMARY KEY ("survey_id")
);

;
CREATE TABLE "survey_answer" (
  "survey_answer_id" uuid NOT NULL,
  "survey_response_id" uuid NOT NULL,
  "survey_question_id" uuid NOT NULL,
  "answer_text" character varying NOT NULL,
  PRIMARY KEY ("survey_answer_id")
);
CREATE INDEX "survey_answer_idx_survey_question_id" on "survey_answer" ("survey_question_id");
CREATE INDEX "survey_answer_idx_survey_response_id" on "survey_answer" ("survey_response_id");

;
CREATE TABLE "survey_question" (
  "survey_question_id" uuid NOT NULL,
  "survey_id" uuid NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  "question_text" character varying NOT NULL,
  PRIMARY KEY ("survey_question_id")
);
CREATE INDEX "survey_question_idx_survey_id" on "survey_question" ("survey_id");

;
CREATE TABLE "survey_response" (
  "survey_response_id" uuid NOT NULL,
  "survey_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("survey_response_id")
);
CREATE INDEX "survey_response_idx_member_id" on "survey_response" ("member_id");
CREATE INDEX "survey_response_idx_survey_id" on "survey_response" ("survey_id");

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
ALTER TABLE "survey_answer" ADD CONSTRAINT "survey_answer_fk_survey_question_id" FOREIGN KEY ("survey_question_id")
  REFERENCES "survey_question" ("survey_question_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "survey_answer" ADD CONSTRAINT "survey_answer_fk_survey_response_id" FOREIGN KEY ("survey_response_id")
  REFERENCES "survey_response" ("survey_response_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "survey_question" ADD CONSTRAINT "survey_question_fk_survey_id" FOREIGN KEY ("survey_id")
  REFERENCES "survey" ("survey_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "survey_response" ADD CONSTRAINT "survey_response_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "survey_response" ADD CONSTRAINT "survey_response_fk_survey_id" FOREIGN KEY ("survey_id")
  REFERENCES "survey" ("survey_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE audit_log ALTER COLUMN changing_member_id DROP NOT NULL;

;
ALTER TABLE members ADD COLUMN linked_member_id uuid;

;
CREATE INDEX members_idx_linked_member_id on members (linked_member_id);

;
ALTER TABLE members ADD CONSTRAINT members_fk_linked_member_id FOREIGN KEY (linked_member_id)
  REFERENCES members (member_id) DEFERRABLE;

;

COMMIT;

