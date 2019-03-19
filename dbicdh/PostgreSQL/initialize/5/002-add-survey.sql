BEGIN;

INSERT INTO survey VALUES
	('c061cc14-0a56-4c6b-b589-32760c2e77f6', 'Reasons for Cancellation')
;

INSERT INTO survey_question VALUES
	('6f38821c-1905-4d75-bd71-0ad21b2f187c', 'c061cc14-0a56-4c6b-b589-32760c2e77f6', 1, 'Why are you terminating your membership?'),
	('6560957a-b1ca-4757-93e3-313c5a22679a', 'c061cc14-0a56-4c6b-b589-32760c2e77f6', 2, 'Please provide any other comments you have.')
;

COMMIT;
