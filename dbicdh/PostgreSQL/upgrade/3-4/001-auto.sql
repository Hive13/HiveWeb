-- Convert schema '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/3/001-auto.yml' to '/home/greg/git/HiveWeb/bin/../dbicdh/_source/deploy/4/001-auto.yml':;
INSERT INTO device SELECT lamp_id, 'thiskeyisakey!!!', REPLACE(LOWER(name), ' ', '_'), NULL, 2, 3 FROM lamp;

;
BEGIN;

;
ALTER TABLE lamp_bulb DROP CONSTRAINT lamp_bulb_fk_lamp_id;

;
DROP INDEX lamp_bulb_idx_lamp_id;

;
ALTER TABLE lamp_bulb RENAME COLUMN lamp_id TO bulb_id;

;
CREATE INDEX lamp_bulb_idx_device_id on lamp_bulb (device_id);

;
ALTER TABLE lamp_bulb ADD CONSTRAINT lamp_bulb_fk_device_id FOREIGN KEY (device_id)
  REFERENCES device (device_id) DEFERRABLE;

;
DROP TABLE lamp CASCADE;

;

COMMIT;

