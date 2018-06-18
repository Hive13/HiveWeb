	{
	'Model::DB' =>
		{
		schema_class => 'HiveWeb::Schema',
		connect_info =>
			{
			dsn      => 'dbi:Pg:dbname=door;host=honeycomb.at.hive13.org;sslmode=require',
			user     => 'access',
			password => '< password >',
			},
		},
	soda =>
		{
		add_amount => 20,
		cost => 1000,
		},
	stripe =>
		{
		public_key => 'pk_live_rP6E92Gc8FKq7yOLGk0kTPmi',
		secret_key => '< put secret key here >',
		},
	email =>
		{
		from        => 'donotreply@hive13.org',
		from_name   => 'Hive13 intweb',
		auth        => '< put auth password here >',
		'Net::SMTP' =>
			{
			Hello => 'intweb.at.hive13.org',
			Host  => 'smtp.gmail.com',
			SSL   => 1
			},
		forgot =>
			{
			temp_plain => 'email/forgot_password_plain.tt',
			subject    => 'Hive13 intweb password reset',
			},
		assigned_slot =>
			{
			temp_plain => 'email/assigned_slot_plain.tt',
			subject    => 'Storage Slot assigned at Hive13',
			},
		},
	priorities =>
		{
		'application.create' => 50,
		'password.reset'     => 1,
		},
	application =>
		{
		email_address => 'leadership@hive13.org',
		pending_group => 'pending_applications',
		},
	}
