BEGIN;

INSERT INTO panel VALUES
	('53d6417f-2066-4f9d-8163-ce933b513148', 'status', 'Current Hive Status', 'panel-info', NULL, 't', 't', 40),
	('598eac32-7f90-4a58-9a5b-83a37069588b', 'heatmap', 'Activity Heatmap', 'panel-default', 'user', 'f', 'f', 60),
	('0b93509a-490f-4448-a85c-15fc28ffd0c3', 'application', 'Application Status', 'panel-warning', 'pending_applications', 'f', 't', 80),
	('14a2e272-55ce-482d-8c02-f37ebc303eed', 'soda', 'Soda Credits', 'panel-default', 'user', 'f', 't', 100),
	('142a5448-9512-4da4-8f20-98b7174dc234', 'curse', 'Notifications', 'panel-danger', 'user', 'f', 't', 120),
	('96690f16-3ade-4ca1-8d01-d356eca5df97', 'storage', 'My Storage Slots', 'panel-success', 'members', 'f', 't', 140),
	('de2361a8-5767-4baa-8112-c9474eebe05e', 'applications', 'Pending Applications', 'panel-info', 'board', 'f', 't', 160),
	('3f11e943-d36b-4b0d-b01e-8d0aed688b55', 'access', 'Recent Accesses', 'panel-primary', 'board', 'f', 't', 180),
	('2c2d6b42-0418-4a8e-99a7-47cf5d3af5d5', 'storage_status', 'Storage Overview', 'panel-info', 'storage', 'f', 't', 200),
	('171b87b7-aa56-43d6-afaf-5f39d0ddd1ce', 'lights', 'Light Control', 'panel-warning', 'lights', 'f', 't', 220)
;


COMMIT;
