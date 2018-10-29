BEGIN;

INSERT INTO storage_slot_type (type_id, name, can_request) VALUES
	('ce23f448-f9bb-420f-90f1-c9e226189c60', 'Member Storage Slot', 't'),
	('ecfcdf63-c04e-4034-814a-b43541b3ac76', 'Vertical Wood Storage Slot', 't'),
	('1fc943ed-fe6e-4a01-8798-da3dc814fa22', 'Half-Height Vertical Storage Slot', 't'),
	('6af9cd58-2dcd-4984-ad2a-57b8cf98ac60', 'Hive Reserved Slot', 'f');

UPDATE storage_slot SET type_id = 'ce23f448-f9bb-420f-90f1-c9e226189c60';
ALTER TABLE storage_slot ALTER COLUMN type_id SET NOT NULL;

UPDATE storage_request SET type_id = 'ce23f448-f9bb-420f-90f1-c9e226189c60';
ALTER TABLE storage_request ALTER COLUMN type_id SET NOT NULL;

COMMIT;
