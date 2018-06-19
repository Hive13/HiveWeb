use IO::Socket::SSL;

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
		from        => 'intweb@hive13.org',
		from_name   => 'Hive13 Intweb',
		auth        => '< put auth password here >',
		list        => '<intwebsandbox.hive13.org>',
		'Net::SMTP' =>
			{
			Hello => 'intweb.at.hive13.org',
			Host  => 'smtp.gmail.com',
			SSL   => 1
			},
		'Net::IMAP' =>
			{
			port => 993,
			host => 'imap.gmail.com',
			use_ssl => 1,
			ssl_options =>
				[
				SSL_ca_path => "/etc/ssl/certs/",
				SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
				],
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
		'application.create'         => 50,
		'application.attach_picture' => 60,
		'application.mark_submitted' => 60,
		'application.attach_form'    => 60,
		'password.reset'             => 1,
		},
	application =>
		{
		email_address => 'intwebsandbox@hive13.org',
		pending_group => 'pending_applications',
		create =>
			{
			temp_plain => 'email/new_application_plain.tt',
			},
		mark_submitted =>
			{
			temp_plain => 'email/application_submitted_plain.tt',
			},
		attach_picture =>
			{
			temp_plain => 'email/application_picture_attached_plain.tt',
			},
		attach_form =>
			{
			temp_plain => 'email/application_form_attached_plain.tt',
			},

		},
	}
