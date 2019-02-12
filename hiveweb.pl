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
	base_url => 'https://intweb.at.hive13.org/',
	soda =>
		{
		add_amount => 20,
		cost => 1000,
		},
	paypal =>
		{
		gateway_url => 'https://www.sandbox.paypal.com',
		},
	stripe =>
		{
		public_key => 'pk_live_FI8RhhPdbD6tTjAHtPbkrVi5',
		secret_key => '< put secret key here >',
		},
	cancellations =>
		{
		message_groups =>
			{
			40 => 'late_payment_40',
			60 => 'late_payment_60',
			80 => 'late_payment_80',
			},
		late_email    => 'member.past_due',
		expire_days   => 90,
		member_group  => 'members',
		pending_group => 'pending_cancellations',
		},
	email =>
		{
		notify_to   => 'intwebsandbox@hive13.org',
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
		requested_slot =>
			{
			temp_plain => 'email/requested_slot_plain.tt',
			subject    => 'Storage Slot requested at Hive13',
			},
		member =>
			{
			welcome =>
				{
				temp_plain => 'email/welcome.tt',
				subject    => 'Welcome to Hive13',
				},
			confirm_cancel =>
				{
				temp_plain => 'email/member/confirm_cancel_plain.tt',
				subject    => 'Hive13 Subscription Cancelled',
				},
			notify_cancel =>
				{
				temp_plain => 'email/member/notify_cancel_plain.tt',
				subject    => 'Member Subscription Cancelled',
				},
			},
		},
	priorities =>
		{
		'application.create'         => 50,
		'application.attach_picture' => 60,
		'application.mark_submitted' => 60,
		'application.attach_form'    => 60,
		'application.update'         => 60,
		'application.finalize'       => 70,
		'application.pay'            => 80,
		'member.confirm_cancel'      => 100,
		'member.notify_cancel'       => 100,
		'member.past_due'            => 40,
		'member.welcome'             => 2,
		'password.reset'             => 1,
		'storage.assign'             => 100,
		'storage.request'            => 100,
		},
	application =>
		{
		email_address => 'intwebsandbox@hive13.org',
		pending_group => 'pending_applications',
		create =>
			{
			temp_plain => 'email/application/created_plain.tt',
			},
		mark_submitted =>
			{
			temp_plain => 'email/application/submitted_plain.tt',
			},
		attach_picture =>
			{
			temp_plain => 'email/application/picture_attached_plain.tt',
			},
		attach_form =>
			{
			temp_plain => 'email/application/form_attached_plain.tt',
			},
		update =>
			{
			temp_plain => 'email/application/updated_plain.tt',
			},
		finalize =>
			{
			temp_plain => 'email/application/finalize_plain.tt',
			},
		pay =>
			{
			temp_plain => 'email/application/pay_plain.tt',
			},
		},
	}
