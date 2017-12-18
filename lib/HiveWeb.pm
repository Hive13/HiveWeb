package HiveWeb;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
	-Debug
	ConfigLoader
	Static::Simple
	
	Authentication
	Authorization::ACL
	Session
	Session::Store::File
	Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in hiveweb.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config
	(
	name => 'HiveWeb',
	default_view => 'HTML',
	# Disable deprecated behavior needed by old applications
	disable_component_resolution_regex_fallback => 1,
	enable_catalyst_header => 1, # Send X-Catalyst header
	'View::JSON' =>
		{
		expose_stash      => 'out',
		json_encoder_args =>
			{
			convert_blessed => 1,
			},
		},
	'View::ChecksummedJSON' =>
		{
		expose_stash      => 'out',
		json_encoder_args =>
			{
			convert_blessed => 1,
			},
		},
	'View::HTML' =>
		{
		INCLUDE_PATH =>
			[
			__PACKAGE__->path_to('root', 'src'),
			],
		EVAL_PERL => 1,
		},
	'View::TT' =>
		{
		INCLUDE_PATH =>
			[
			__PACKAGE__->path_to('root', 'src'),
			],
		EVAL_PERL => 1,
		},
	'Plugin::Authentication' =>
		{
		'default_realm' => 'members',
		members =>
			{
			store =>
				{
				class      => 'DBIx::Class',
				user_model => 'DB::Member',
				id_field   => 'member_id',
				},
			credential =>
				{
				password_type  => 'self_check',
				password_field => 'password',
				class          => 'Password',
				},
			},
		},
	);

__PACKAGE__->setup();
__PACKAGE__->deny_access_unless("/api/admin", sub
	{
	my $c = shift;

	return 0
		if (!$c->user());
	return $c->user()->is_admin();
	});
__PACKAGE__->deny_access_unless("/admin", sub
	{
	my $c = shift;

	return 0
		if (!$c->user());
	return $c->user()->is_admin();
	});

1;
