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
	storage =>
		{
		remind       => '1 month',
		remind_group => 'needs_storage_renewal',
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
	slack =>
		{
		token => '<a LEGACY token>',
		channels =>
			[
			'C04Q9C12L',
			'C04Q9C12U',
			],
		api => 'https://slack.com/api/users.admin.invite',
		},
	membership =>
		{
		message_groups =>
			{
			40 => 'late_payment_40',
			60 => 'late_payment_60',
			80 => 'late_payment_80',
			},
		late_email    => 'member.past_due',
		expire_days   => 90,
		past_due_days => 31,
		member_group  => 'members',
		pending_group => 'pending_cancellations',
		expire_group  => 'pending_expiry',
		survey_uuid   => 'c061cc14-0a56-4c6b-b589-32760c2e77f6',
		apply_group   => 'pending_applications',
		welcome_group => 'pending_payments',
		},
	email =>
		{
		from        => 'intweb@hive13.org',
		from_name   => 'Hive13 Intweb',
		auth        => '< put auth password here >',
		list        => '<intwebsandbox.hive13.org>',
		priority    => 100,
		'Net::SMTP' =>
			{
			Hello => 'intweb.at.hive13.org',
			Host  => 'smtp.gmail.com',
			SSL   => 1
			},
		storage =>
			{
			row     => 'StorageSlot',
			row_as  => 'slot',
			to      => 'slot.member',
			renew   => { subject => 'Storage Slot renewed at Hive13' },
			assign  => { subject => 'Storage Slot assigned at Hive13' },
			request =>
				{
				row     => 'StorageRequest',
				row_as  => 'request',
				to      => 'storage',
				subject => 'Storage Slot requested at Hive13',
				},
			renew_remind => { subject => 'Storage Slot needs renewal at Hive13' },
			},
		member =>
			{
			row    => 'Member',
			row_as => 'member',
			to     => 'member',
			welcome =>
				{
				priority => 20,
				subject  => 'Welcome to Hive13',
				},
			alert_credit =>
				{
				priority => 5,
				subject  => 'Hive13 Soda Credit Alert',
				},
			confirm_cancel => { subject => 'Hive13 Subscription Cancelled' },
			alert_failed   => { subject => 'Hive13 Subscription Payment Failed' },
			notify_cancel  =>
				{
				subject => 'Member Subscription Cancelled',
				to      => 'intwebsandbox@hive13.org',
				},
			notify_failed  =>
				{
				subject => 'Member Payment Failed',
				to      => 'intwebsandbox@hive13.org',
				},
			password_reset =>
				{
				priority => 1,
				subject  => 'Hive13 intweb password reset',
				},
			past_due =>
				{
				subject  => 'Your Hive13 Subscription is past due',
				priority => 40,
				},
			},
		notify =>
			{
			row    => 'SurveyResponse',
			row_as => 'survey',
			to     => 'intwebsandbox@hive13.org',
			term   =>
				{
				priority => 90,
				subject  => 'Member is Resigning',
				},
			},
		application =>
			{
			row      => 'Application',
			row_as   => 'application',
			to       => 'intwebsandbox@hive13.org',
			priority => 60,
			create   => { priority => 50 },
			finalize => { priority => 70 },
			pay      => { priority => 80 },
			}
		},
	reports =>
		{
		membership =>
			{
			to        => 'intwebsandbox@hive13.org',
			subject   => 'Membership Report',
			temp_html => 'admin/reports/member.tt',
			},
		},
	quiet_hours =>
		{
		start =>
			{
			hour   => 22,
			minute => 30,
			second => 0,
			},
		end =>
			{
			hour   => 7,
			minute => 0,
			second => 0,
			},
		},
	}
