-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/9/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "survey_choice" (
  "survey_choice_id" uuid NOT NULL,
  "survey_question_id" uuid NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  "choice_name" character varying NOT NULL,
  "choice_text" character varying,
  PRIMARY KEY ("survey_choice_id")
);
CREATE INDEX "survey_choice_idx_survey_question_id" on "survey_choice" ("survey_question_id");

;
ALTER TABLE "survey_choice" ADD CONSTRAINT "survey_choice_fk_survey_question_id" FOREIGN KEY ("survey_question_id")
  REFERENCES "survey_question" ("survey_question_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;

COMMIT;

