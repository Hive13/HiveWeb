BEGIN;

UPDATE storage_slot_type SET default_expire_time = '3 month' WHERE type_id = 'ecfcdf63-c04e-4034-814a-b43541b3ac76';

COMMIT;
