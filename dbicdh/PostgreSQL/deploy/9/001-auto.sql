-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Mar 16 23:13:30 2019
-- 
;
--
-- Table: curse
--
CREATE TABLE "curse" (
  "curse_id" uuid NOT NULL,
  "priority" integer DEFAULT 10000 NOT NULL,
  "protect_group_cast" boolean DEFAULT true NOT NULL,
  "protect_user_cast" boolean DEFAULT true NOT NULL,
  "name" character varying NOT NULL,
  "display_name" character varying NOT NULL,
  "notification_markdown" text,
  PRIMARY KEY ("curse_id")
);

;
--
-- Table: device
--
CREATE TABLE "device" (
  "device_id" uuid NOT NULL,
  "key" bytea NOT NULL,
  "name" character varying(64) NOT NULL,
  "nonce" bytea,
  "min_version" integer DEFAULT 1 NOT NULL,
  "max_version" integer DEFAULT 1 NOT NULL,
  PRIMARY KEY ("device_id")
);

;
--
-- Table: item
--
CREATE TABLE "item" (
  "item_id" uuid NOT NULL,
  "name" character(32) NOT NULL,
  "display_name" character varying NOT NULL,
  PRIMARY KEY ("item_id")
);

;
--
-- Table: lamp_color
--
CREATE TABLE "lamp_color" (
  "color_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  "html_color" character(6) NOT NULL,
  PRIMARY KEY ("color_id")
);

;
--
-- Table: lamp_preset
--
CREATE TABLE "lamp_preset" (
  "preset_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("preset_id")
);

;
--
-- Table: log
--
CREATE TABLE "log" (
  "log_id" uuid NOT NULL,
  "create_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "type" character varying NOT NULL,
  "message" text NOT NULL,
  PRIMARY KEY ("log_id")
);

;
--
-- Table: mgroup
--
CREATE TABLE "mgroup" (
  "mgroup_id" uuid NOT NULL,
  "name" character(32),
  PRIMARY KEY ("mgroup_id")
);

;
--
-- Table: panel
--
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
--
-- Table: session
--
CREATE TABLE "session" (
  "id" character(72) NOT NULL,
  "session_data" text,
  "expires" integer NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: soda_type
--
CREATE TABLE "soda_type" (
  "soda_type_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("soda_type_id")
);

;
--
-- Table: storage_location
--
CREATE TABLE "storage_location" (
  "location_id" uuid NOT NULL,
  "parent_id" uuid,
  "name" character varying(32) NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  PRIMARY KEY ("location_id")
);
CREATE INDEX "storage_location_idx_parent_id" on "storage_location" ("parent_id");

;
--
-- Table: storage_slot_type
--
CREATE TABLE "storage_slot_type" (
  "type_id" uuid NOT NULL,
  "name" character varying NOT NULL,
  "can_request" boolean DEFAULT 't' NOT NULL,
  PRIMARY KEY ("type_id")
);

;
--
-- Table: survey
--
CREATE TABLE "survey" (
  "survey_id" uuid NOT NULL,
  "title" character varying,
  PRIMARY KEY ("survey_id")
);

;
--
-- Table: curse_action
--
CREATE TABLE "curse_action" (
  "curse_action_id" uuid NOT NULL,
  "curse_id" uuid NOT NULL,
  "path" character varying NOT NULL,
  "action" character varying NOT NULL,
  "message" text NOT NULL,
  PRIMARY KEY ("curse_action_id")
);
CREATE INDEX "curse_action_idx_curse_id" on "curse_action" ("curse_id");

;
--
-- Table: image
--
CREATE TABLE "image" (
  "image_id" uuid NOT NULL,
  "image" bytea NOT NULL,
  "thumbnail" bytea,
  "created_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "updated_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "content_type" character varying,
  PRIMARY KEY ("image_id")
);

;
--
-- Table: members
--
CREATE TABLE "members" (
  "member_id" uuid NOT NULL,
  "fname" character varying(255),
  "lname" character varying(255),
  "email" citext NOT NULL,
  "paypal_email" citext,
  "phone" bigint,
  "encrypted_password" character varying(255) NOT NULL,
  "vend_credits" integer DEFAULT 0 NOT NULL,
  "vend_total" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp without time zone DEFAULT current_timestamp NOT NULL,
  "updated_at" timestamp without time zone DEFAULT current_timestamp NOT NULL,
  "handle" citext,
  "member_image_id" uuid,
  "door_count" integer,
  "totp_secret" bytea,
  "linked_member_id" uuid,
  PRIMARY KEY ("member_id"),
  CONSTRAINT "index_members_on_email" UNIQUE ("email"),
  CONSTRAINT "members_handle_key" UNIQUE ("handle")
);
CREATE INDEX "members_idx_member_image_id" on "members" ("member_image_id");
CREATE INDEX "members_idx_linked_member_id" on "members" ("linked_member_id");
CREATE INDEX "members_fname_lname_idx" on "members" ("fname", "lname");
CREATE INDEX "members_lname_fname_idx" on "members" ("lname", "fname");

;
--
-- Table: soda_status
--
CREATE TABLE "soda_status" (
  "soda_id" uuid NOT NULL,
  "name" character varying(32) NOT NULL,
  "sold_out" boolean DEFAULT 'f' NOT NULL,
  "slot_number" integer NOT NULL,
  "soda_type_id" uuid NOT NULL,
  PRIMARY KEY ("soda_id")
);
CREATE INDEX "soda_status_idx_soda_type_id" on "soda_status" ("soda_type_id");

;
--
-- Table: survey_question
--
CREATE TABLE "survey_question" (
  "survey_question_id" uuid NOT NULL,
  "survey_id" uuid NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  "question_text" character varying NOT NULL,
  PRIMARY KEY ("survey_question_id")
);
CREATE INDEX "survey_question_idx_survey_id" on "survey_question" ("survey_id");

;
--
-- Table: temp_log
--
CREATE TABLE "temp_log" (
  "temp_log_id" uuid NOT NULL,
  "create_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "item_id" uuid NOT NULL,
  "temperature" integer NOT NULL,
  PRIMARY KEY ("temp_log_id")
);
CREATE INDEX "temp_log_idx_item_id" on "temp_log" ("item_id");
CREATE INDEX "recent_temp" on "temp_log" ("item_id", "create_time");

;
--
-- Table: action
--
CREATE TABLE "action" (
  "action_id" uuid NOT NULL,
  "queued_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "queuing_member_id" uuid NOT NULL,
  "priority" interger DEFAULT '1000' NOT NULL,
  "action_type" character varying NOT NULL,
  "row_id" uuid NOT NULL,
  PRIMARY KEY ("action_id")
);
CREATE INDEX "action_idx_queuing_member_id" on "action" ("queuing_member_id");

;
--
-- Table: application
--
CREATE TABLE "application" (
  "application_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "address1" character varying NOT NULL,
  "address2" character varying,
  "city" character varying NOT NULL,
  "state" character(2) NOT NULL,
  "zip" character(9) NOT NULL,
  "contact_name" character varying,
  "contact_phone" bigint,
  "form_id" uuid,
  "topic_id" character varying,
  "picture_id" uuid,
  "created_at" timestamp without time zone DEFAULT current_timestamp NOT NULL,
  "updated_at" timestamp without time zone DEFAULT current_timestamp NOT NULL,
  "app_turned_in_at" timestamp with time zone,
  "thread_message_id" character varying,
  "decided_at" timestamp with time zone,
  "final_result" character varying,
  "helper" character varying,
  PRIMARY KEY ("application_id")
);
CREATE INDEX "application_idx_form_id" on "application" ("form_id");
CREATE INDEX "application_idx_member_id" on "application" ("member_id");
CREATE INDEX "application_idx_picture_id" on "application" ("picture_id");

;
--
-- Table: audit_log
--
CREATE TABLE "audit_log" (
  "audit_id" uuid NOT NULL,
  "change_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "changed_member_id" uuid NOT NULL,
  "changing_member_id" uuid,
  "change_type" character varying NOT NULL,
  "notes" character varying,
  PRIMARY KEY ("audit_id")
);
CREATE INDEX "audit_log_idx_changed_member_id" on "audit_log" ("changed_member_id");
CREATE INDEX "audit_log_idx_changing_member_id" on "audit_log" ("changing_member_id");

;
--
-- Table: badge
--
CREATE TABLE "badge" (
  "badge_id" uuid NOT NULL,
  "badge_number" integer NOT NULL,
  "member_id" uuid NOT NULL,
  PRIMARY KEY ("badge_id")
);
CREATE INDEX "badge_idx_member_id" on "badge" ("member_id");

;
--
-- Table: device_item
--
CREATE TABLE "device_item" (
  "device_id" uuid NOT NULL,
  "item_id" uuid NOT NULL,
  PRIMARY KEY ("device_id", "item_id")
);
CREATE INDEX "device_item_idx_device_id" on "device_item" ("device_id");
CREATE INDEX "device_item_idx_item_id" on "device_item" ("item_id");

;
--
-- Table: ipn_message
--
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
--
-- Table: item_mgroup
--
CREATE TABLE "item_mgroup" (
  "item_id" uuid NOT NULL,
  "mgroup_id" uuid NOT NULL,
  PRIMARY KEY ("item_id", "mgroup_id")
);
CREATE INDEX "item_mgroup_idx_item_id" on "item_mgroup" ("item_id");
CREATE INDEX "item_mgroup_idx_mgroup_id" on "item_mgroup" ("mgroup_id");

;
--
-- Table: lamp_bulb
--
CREATE TABLE "lamp_bulb" (
  "bulb_id" uuid NOT NULL,
  "device_id" uuid NOT NULL,
  "color_id" uuid NOT NULL,
  "slot" integer NOT NULL,
  PRIMARY KEY ("bulb_id")
);
CREATE INDEX "lamp_bulb_idx_color_id" on "lamp_bulb" ("color_id");
CREATE INDEX "lamp_bulb_idx_device_id" on "lamp_bulb" ("device_id");

;
--
-- Table: reset_token
--
CREATE TABLE "reset_token" (
  "token_id" uuid NOT NULL,
  "created_at" timestamp without time zone DEFAULT current_timestamp NOT NULL,
  "member_id" uuid NOT NULL,
  "valid" boolean DEFAULT true NOT NULL,
  PRIMARY KEY ("token_id")
);
CREATE INDEX "reset_token_idx_member_id" on "reset_token" ("member_id");

;
--
-- Table: sign_in_log
--
CREATE TABLE "sign_in_log" (
  "sign_in_id" uuid NOT NULL,
  "sign_in_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "member_id" uuid NOT NULL,
  "valid" boolean NOT NULL,
  "remote_ip" inet NOT NULL,
  "email" character varying NOT NULL,
  PRIMARY KEY ("sign_in_id")
);
CREATE INDEX "sign_in_log_idx_member_id" on "sign_in_log" ("member_id");

;
--
-- Table: access_log
--
CREATE TABLE "access_log" (
  "access_id" uuid NOT NULL,
  "access_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "item_id" uuid NOT NULL,
  "member_id" uuid,
  "granted" boolean NOT NULL,
  "badge_id" integer,
  PRIMARY KEY ("access_id")
);
CREATE INDEX "access_log_idx_item_id" on "access_log" ("item_id");
CREATE INDEX "access_log_idx_member_id" on "access_log" ("member_id");
CREATE INDEX "access_log_member_id_access_time_idx" on "access_log" ("member_id", "access_time");
CREATE INDEX "recent" on "access_log" ("access_time");

;
--
-- Table: member_curse
--
CREATE TABLE "member_curse" (
  "member_curse_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "curse_id" uuid NOT NULL,
  "issued_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "lifted_at" timestamp with time zone,
  "issuing_member_id" uuid NOT NULL,
  "issuing_notes" text,
  "lifting_member_id" uuid,
  "lifting_notes" text,
  PRIMARY KEY ("member_curse_id")
);
CREATE INDEX "member_curse_idx_curse_id" on "member_curse" ("curse_id");
CREATE INDEX "member_curse_idx_issuing_member_id" on "member_curse" ("issuing_member_id");
CREATE INDEX "member_curse_idx_lifting_member_id" on "member_curse" ("lifting_member_id");
CREATE INDEX "member_curse_idx_member_id" on "member_curse" ("member_id");

;
--
-- Table: member_mgroup
--
CREATE TABLE "member_mgroup" (
  "member_id" uuid NOT NULL,
  "mgroup_id" uuid NOT NULL,
  PRIMARY KEY ("member_id", "mgroup_id")
);
CREATE INDEX "member_mgroup_idx_member_id" on "member_mgroup" ("member_id");
CREATE INDEX "member_mgroup_idx_mgroup_id" on "member_mgroup" ("mgroup_id");

;
--
-- Table: member_panel
--
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
--
-- Table: payment
--
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
--
-- Table: survey_response
--
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
--
-- Table: vend_log
--
CREATE TABLE "vend_log" (
  "vend_id" uuid NOT NULL,
  "vend_time" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "device_id" uuid NOT NULL,
  "member_id" uuid,
  "vended" boolean NOT NULL,
  "badge_id" integer,
  PRIMARY KEY ("vend_id")
);
CREATE INDEX "vend_log_idx_device_id" on "vend_log" ("device_id");
CREATE INDEX "vend_log_idx_member_id" on "vend_log" ("member_id");

;
--
-- Table: lamp_bulb_preset
--
CREATE TABLE "lamp_bulb_preset" (
  "preset_id" uuid NOT NULL,
  "bulb_id" uuid NOT NULL,
  "value" boolean NOT NULL,
  PRIMARY KEY ("preset_id", "bulb_id")
);
CREATE INDEX "lamp_bulb_preset_idx_bulb_id" on "lamp_bulb_preset" ("bulb_id");
CREATE INDEX "lamp_bulb_preset_idx_preset_id" on "lamp_bulb_preset" ("preset_id");

;
--
-- Table: storage_slot
--
CREATE TABLE "storage_slot" (
  "slot_id" uuid NOT NULL,
  "name" character varying(32) NOT NULL,
  "member_id" uuid,
  "location_id" uuid NOT NULL,
  "type_id" uuid NOT NULL,
  "sort_order" integer DEFAULT 1000 NOT NULL,
  PRIMARY KEY ("slot_id")
);
CREATE INDEX "storage_slot_idx_location_id" on "storage_slot" ("location_id");
CREATE INDEX "storage_slot_idx_member_id" on "storage_slot" ("member_id");
CREATE INDEX "storage_slot_idx_type_id" on "storage_slot" ("type_id");

;
--
-- Table: storage_request
--
CREATE TABLE "storage_request" (
  "request_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT current_timestamp NOT NULL,
  "notes" text,
  "status" character varying DEFAULT 'requested' NOT NULL,
  "slot_id" uuid,
  "deciding_member_id" uuid,
  "decision_notes" text,
  "decided_at" timestamp with time zone,
  "hidden" boolean DEFAULT 'f' NOT NULL,
  "type_id" uuid NOT NULL,
  PRIMARY KEY ("request_id")
);
CREATE INDEX "storage_request_idx_deciding_member_id" on "storage_request" ("deciding_member_id");
CREATE INDEX "storage_request_idx_member_id" on "storage_request" ("member_id");
CREATE INDEX "storage_request_idx_slot_id" on "storage_request" ("slot_id");
CREATE INDEX "storage_request_idx_type_id" on "storage_request" ("type_id");

;
--
-- Table: survey_answer
--
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
--
-- Foreign Key Definitions
--

;
ALTER TABLE "storage_location" ADD CONSTRAINT "storage_location_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "storage_location" ("location_id") DEFERRABLE;

;
ALTER TABLE "curse_action" ADD CONSTRAINT "curse_action_fk_curse_id" FOREIGN KEY ("curse_id")
  REFERENCES "curse" ("curse_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "image" ADD CONSTRAINT "image_fk_image_id" FOREIGN KEY ("image_id")
  REFERENCES "members" ("member_image_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "members" ADD CONSTRAINT "members_fk_member_image_id" FOREIGN KEY ("member_image_id")
  REFERENCES "image" ("image_id") DEFERRABLE;

;
ALTER TABLE "members" ADD CONSTRAINT "members_fk_linked_member_id" FOREIGN KEY ("linked_member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "soda_status" ADD CONSTRAINT "soda_status_fk_soda_type_id" FOREIGN KEY ("soda_type_id")
  REFERENCES "soda_type" ("soda_type_id") DEFERRABLE;

;
ALTER TABLE "survey_question" ADD CONSTRAINT "survey_question_fk_survey_id" FOREIGN KEY ("survey_id")
  REFERENCES "survey" ("survey_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "temp_log" ADD CONSTRAINT "temp_log_fk_item_id" FOREIGN KEY ("item_id")
  REFERENCES "item" ("item_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "action" ADD CONSTRAINT "action_fk_queuing_member_id" FOREIGN KEY ("queuing_member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "application" ADD CONSTRAINT "application_fk_form_id" FOREIGN KEY ("form_id")
  REFERENCES "image" ("image_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "application" ADD CONSTRAINT "application_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "application" ADD CONSTRAINT "application_fk_picture_id" FOREIGN KEY ("picture_id")
  REFERENCES "image" ("image_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_fk_changed_member_id" FOREIGN KEY ("changed_member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_fk_changing_member_id" FOREIGN KEY ("changing_member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "badge" ADD CONSTRAINT "badge_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "device_item" ADD CONSTRAINT "device_item_fk_device_id" FOREIGN KEY ("device_id")
  REFERENCES "device" ("device_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "device_item" ADD CONSTRAINT "device_item_fk_item_id" FOREIGN KEY ("item_id")
  REFERENCES "item" ("item_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "ipn_message" ADD CONSTRAINT "ipn_message_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "item_mgroup" ADD CONSTRAINT "item_mgroup_fk_item_id" FOREIGN KEY ("item_id")
  REFERENCES "item" ("item_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "item_mgroup" ADD CONSTRAINT "item_mgroup_fk_mgroup_id" FOREIGN KEY ("mgroup_id")
  REFERENCES "mgroup" ("mgroup_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "lamp_bulb" ADD CONSTRAINT "lamp_bulb_fk_color_id" FOREIGN KEY ("color_id")
  REFERENCES "lamp_color" ("color_id") DEFERRABLE;

;
ALTER TABLE "lamp_bulb" ADD CONSTRAINT "lamp_bulb_fk_device_id" FOREIGN KEY ("device_id")
  REFERENCES "device" ("device_id") DEFERRABLE;

;
ALTER TABLE "reset_token" ADD CONSTRAINT "reset_token_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "sign_in_log" ADD CONSTRAINT "sign_in_log_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "access_log" ADD CONSTRAINT "access_log_fk_item_id" FOREIGN KEY ("item_id")
  REFERENCES "item" ("item_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "access_log" ADD CONSTRAINT "access_log_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_curse" ADD CONSTRAINT "member_curse_fk_curse_id" FOREIGN KEY ("curse_id")
  REFERENCES "curse" ("curse_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_curse" ADD CONSTRAINT "member_curse_fk_issuing_member_id" FOREIGN KEY ("issuing_member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_curse" ADD CONSTRAINT "member_curse_fk_lifting_member_id" FOREIGN KEY ("lifting_member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_curse" ADD CONSTRAINT "member_curse_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_mgroup" ADD CONSTRAINT "member_mgroup_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_mgroup" ADD CONSTRAINT "member_mgroup_fk_mgroup_id" FOREIGN KEY ("mgroup_id")
  REFERENCES "mgroup" ("mgroup_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_panel" ADD CONSTRAINT "member_panel_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "member_panel" ADD CONSTRAINT "member_panel_fk_panel_id" FOREIGN KEY ("panel_id")
  REFERENCES "panel" ("panel_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_ipn_message_id" FOREIGN KEY ("ipn_message_id")
  REFERENCES "ipn_message" ("ipn_message_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "payment" ADD CONSTRAINT "payment_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "survey_response" ADD CONSTRAINT "survey_response_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "survey_response" ADD CONSTRAINT "survey_response_fk_survey_id" FOREIGN KEY ("survey_id")
  REFERENCES "survey" ("survey_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "vend_log" ADD CONSTRAINT "vend_log_fk_device_id" FOREIGN KEY ("device_id")
  REFERENCES "device" ("device_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "vend_log" ADD CONSTRAINT "vend_log_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "lamp_bulb_preset" ADD CONSTRAINT "lamp_bulb_preset_fk_bulb_id" FOREIGN KEY ("bulb_id")
  REFERENCES "lamp_bulb" ("bulb_id") DEFERRABLE;

;
ALTER TABLE "lamp_bulb_preset" ADD CONSTRAINT "lamp_bulb_preset_fk_preset_id" FOREIGN KEY ("preset_id")
  REFERENCES "lamp_preset" ("preset_id") DEFERRABLE;

;
ALTER TABLE "storage_slot" ADD CONSTRAINT "storage_slot_fk_location_id" FOREIGN KEY ("location_id")
  REFERENCES "storage_location" ("location_id") DEFERRABLE;

;
ALTER TABLE "storage_slot" ADD CONSTRAINT "storage_slot_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "storage_slot" ADD CONSTRAINT "storage_slot_fk_type_id" FOREIGN KEY ("type_id")
  REFERENCES "storage_slot_type" ("type_id");

;
ALTER TABLE "storage_request" ADD CONSTRAINT "storage_request_fk_deciding_member_id" FOREIGN KEY ("deciding_member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "storage_request" ADD CONSTRAINT "storage_request_fk_member_id" FOREIGN KEY ("member_id")
  REFERENCES "members" ("member_id") DEFERRABLE;

;
ALTER TABLE "storage_request" ADD CONSTRAINT "storage_request_fk_slot_id" FOREIGN KEY ("slot_id")
  REFERENCES "storage_slot" ("slot_id") DEFERRABLE;

;
ALTER TABLE "storage_request" ADD CONSTRAINT "storage_request_fk_type_id" FOREIGN KEY ("type_id")
  REFERENCES "storage_slot_type" ("type_id");

;
ALTER TABLE "survey_answer" ADD CONSTRAINT "survey_answer_fk_survey_question_id" FOREIGN KEY ("survey_question_id")
  REFERENCES "survey_question" ("survey_question_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
ALTER TABLE "survey_answer" ADD CONSTRAINT "survey_answer_fk_survey_response_id" FOREIGN KEY ("survey_response_id")
  REFERENCES "survey_response" ("survey_response_id") ON DELETE RESTRICT ON UPDATE RESTRICT;

;
