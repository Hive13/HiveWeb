-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/7/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "member_panel" (
  "member_id" uuid NOT NULL,
  "panel_id" uuid NOT NULL,
  "style" character varying,
  "visible" boolean,
  "sort_order" integer,
  PRIMARY KEY ("member_id", "panel_id")
);
CREATE INDEX "member_panel_idx_member_id" on "member_panel" ("member_id");
CREATE INDEX "member_panel_idx_panel_id" on "member_panel" ("panel_id");

;
CREATE TABLE "panel" (
  "panel_id" uuid NOT NULL,
  "name" character varying(32) NOT NULL,
  "title" character varying(32) NOT NULL,
  "style" character varying(32) NOT NULL,
  "permissions" character varying(32),
  "large" boolean DEFAULT 'f' NOT NULL,
  "visible" boolean DEFAULT 't' NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  PRIMARY KEY ("panel_id")
);

;
ALTER TABLE "member_panel" ADD CONSTRAINT "member_panel_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_panel" ADD CONSTRAINT "member_panel_fk_panel_id" FOREIGN KEY ("panel_id")
  REFERENCES "panel" ("panel_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;

COMMIT;

