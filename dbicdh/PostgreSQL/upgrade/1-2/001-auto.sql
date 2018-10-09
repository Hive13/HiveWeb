-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/1/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "lamp" (
  "lamp_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  "ip_address" inet NOT NULL,
  PRIMARY KEY ("lamp_id")
);

;
CREATE TABLE "lamp_bulb" (
  "bulb_id" uuid NOT NULL,
  "lamp_id" uuid NOT NULL,
  "color_id" uuid NOT NULL,
  "slot" integer NOT NULL,
  PRIMARY KEY ("bulb_id")
);
CREATE INDEX "lamp_bulb_idx_color_id" on "lamp_bulb" ("color_id");
CREATE INDEX "lamp_bulb_idx_lamp_id" on "lamp_bulb" ("lamp_id");

;
CREATE TABLE "lamp_bulb_preset" (
  "preset_id" uuid NOT NULL,
  "bulb_id" uuid NOT NULL,
  "value" boolean NOT NULL,
  PRIMARY KEY ("preset_id", "bulb_id")
);
CREATE INDEX "lamp_bulb_preset_idx_bulb_id" on "lamp_bulb_preset" ("bulb_id");
CREATE INDEX "lamp_bulb_preset_idx_preset_id" on "lamp_bulb_preset" ("preset_id");

;
CREATE TABLE "lamp_color" (
  "color_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  "html_color" character(6) NOT NULL,
  PRIMARY KEY ("color_id")
);

;
CREATE TABLE "lamp_preset" (
  "preset_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("preset_id")
);

;
ALTER TABLE "lamp_bulb" ADD CONSTRAINT "lamp_bulb_fk_color_id" FOREIGN KEY ("color_id")
  REFERENCES "lamp_color" ("color_id") DEFERRABLE;

;
ALTER TABLE "lamp_bulb" ADD CONSTRAINT "lamp_bulb_fk_lamp_id" FOREIGN KEY ("lamp_id")
  REFERENCES "lamp" ("lamp_id") DEFERRABLE;

;
ALTER TABLE "lamp_bulb_preset" ADD CONSTRAINT "lamp_bulb_preset_fk_bulb_id" FOREIGN KEY ("bulb_id")
  REFERENCES "lamp_bulb" ("bulb_id") DEFERRABLE;

;
ALTER TABLE "lamp_bulb_preset" ADD CONSTRAINT "lamp_bulb_preset_fk_preset_id" FOREIGN KEY ("preset_id")
  REFERENCES "lamp_preset" ("preset_id") DEFERRABLE;

;

COMMIT;

