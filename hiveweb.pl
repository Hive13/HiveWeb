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
	}
