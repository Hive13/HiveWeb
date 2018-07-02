package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auto :Private
	{
	my ($self, $c) = @_;

	my $toast = $c->stash()->{auto_toast} = [];
	if (my $f = $c->flash()->{auto_toast})
		{
		push(@$toast, $f);
		}

	delete($c->session()->{need_2fa})
		if (!$c->user());
	$c->detach('/two_factor')
		if ($c->session()->{need_2fa} && $c->request()->path() ne 'two_factor' && $c->request()->path() ne 'logout' && $c->request()->path() ne 'login');

	if (my $user = $c->user())
		{
		my $path  = '/';
		my $paths = ['/'];
		my @parts = split(/\//, $c->request()->path());
		for (my $i = 0; $i < scalar(@parts); $i++)
			{
			$path .= $parts[$i];
			$path .= '/'
				if ($i < (scalar(@parts) - 1));
			push(@$paths, $path);
			}

		my $actions = $c->model('DB::CurseAction')->search(
			{
			issued_at => { '<=' => \'now()'},
			lifted_at => [ undef, { '>=' => \'now()' } ],
			path      => $paths,
			member_id => $c->user()->member_id(),
			},
			{
			prefetch => { curse => 'member_curses' },
			});

		my $msg = [];

		try
			{
			$c->model('DB')->txn_do(sub
				{
				while (my $action = $actions->next())
					{
					my $op    = $action->action();
					my $curse = $action->curse();
					my $mcs   = $curse->member_curses();

					while (my $mc = $mcs->next())
						{
						if ($op eq 'lift')
							{
							$mc->update(
								{
								lifting_member_id => $c->user()->member_id(),
								lifted_at         => \'now()',
								lifting_notes     => "Auto-lifted by visiting $path.",
								});
							push(@$toast, { title => 'Cleared notification "' . $curse->display_name() . '"', text => $action->message() });
							}
						elsif ($op eq 'block')
							{
							push (@$msg, { title => $curse->display_name(), message => $action->message() });
							die;
							}
						}
					}
				});
			}
		catch
			{
			$c->stash()->{messages} = $msg;
			$c->detach('blocked_by_curse', $msg);
			}
		}

	$c->stash()->{extra_css} = [];
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'index.tt';
	}

sub blocked_by_curse :Local :Args(0)
	{
	my ($self, $c, $msg) = @_;

	$c->stash()->{template} = 'blocked_by_curse.tt';
	}

sub two_factor :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->response()->redirect('/')
		if (!$c->session()->{need_2fa});

	$c->stash()->{template} = 'two_factor.tt';
	return
		if ($c->request()->method() eq 'GET');

	my $code = $c->request()->params()->{code};
	if (!$code)
		{
		$c->stash()->{msg} = 'You must enter a Two-Factor Authentication code to continue.';
		return;
		}

	if (!$c->user()->check_2fa($code))
		{
		$c->stash()->{msg} = 'That code is not correct.  Please enter a valid Two-Factor Authentication code to continue.';
		return;
		}

	delete($c->session()->{need_2fa});
	my $return = $c->flash()->{return} || $c->uri_for('/');
	$c->clear_flash();
	$c->response()->redirect($return);
	}

sub login :Local
	{
	my ($self, $c) = @_;

	if ($c->request()->method() eq 'GET')
		{
		$c->response()->redirect($c->uri_for('/'))
			if ($c->user());
		$c->stash()->{template} = 'login.tt';
		return;
		}

	my $params = $c->request()->params();

	my $user = $c->authenticate(
		{
		password     => $params->{password},
		'dbix_class' =>
			{
			searchargs =>
				[
					{
						'-or' =>
							[
							{ handle => $params->{email} },
							{ email  => $params->{email} },
							],
					},
					{
					}
				]
			},
		});
	my $log  = $c->model('DB::SignInLog')->create(
		{
		email     => $params->{email},
		valid     => $user ? 1 : 0,
		member_id => $user ? $user->member_id() : undef,
		remote_ip => $c->request()->address(),
		}) || die $!;
	if ($user)
		{
		if ($user->totp_secret())
			{
			$c->session()->{need_2fa} = 1;
			$c->detach('/two_factor');
			}

		my $return = $c->flash()->{return} || $c->uri_for('/');
		$c->clear_flash();
		$c->response()->redirect($return);
		}
	else
		{
		$c->stash()->{template} = 'login.tt';
		$c->stash()->{msg} = 'The username or password were invalid.';
		$c->response->status(403);
		}
	}

sub logout :Local
	{
	my ($self, $c) = @_;

	$c->logout();
	$c->response()->redirect($c->uri_for('/'));
	}

sub forgot :Local
	{
	my $self     = shift;
	my $c        = shift;
	my $token_id = shift;
	my $stash    = $c->stash();

	if ($token_id)
		{
		my $token = $c->model('DB::ResetToken')->find($token_id);
		$stash->{template} = 'forgot_token.tt';
		$stash->{token}    = $token;
		return;
		}

	if ($c->request()->method() eq 'GET')
		{
		$stash->{template} = 'forgot.tt';
		return;
		}

	my $params = $c->request()->params();
	my $email  = $params->{email};

	my $member = $c->model('DB::Member')->find({ email => $email });

	if ($member)
		{
		$c->model('DB::Action')->create(
			{
			queuing_member_id => $member->member_id(),
			action_type       => 'password.reset',
			row_id            => $member->member_id(),
			});
		}

	$stash->{email}    = $email;
	$stash->{template} = 'forgot_sent.tt';
	}

sub forgot_password :Local
	{
	my $self     = shift;
	my $c        = shift;
	my $token_id = shift;
	my $stash    = $c->stash();
	my $params   = $c->request()->params();
	my $token    = $c->model('DB::ResetToken')->find($token_id);

	$token = undef
		if ($token && !$token->valid());

	if ($token)
		{
		my $date = $token->created_at();
		$date->add({ hours => 24 });
		$token = undef
			if (DateTime->compare($date, DateTime->now() ) < 0);
		}

	$stash->{token}    = $token;
	$stash->{template} = 'forgot_token.tt';

	return
		if (!$token || $c->request()->method() eq 'GET');

	my $member   = $token->member();
	my $password = $params->{password1};

	if ($password ne $params->{password2})
		{
		$stash->{message} = 'The passwords do not match.';
		return;
		}

	$c->model('DB')->txn_do(sub
		{
		$member->set_password($password);
		$token->update({ valid => 0 });
		});

	$stash->{template} = 'forgot_updated.tt';
	}

sub access_denied :Private
	{
	my ($self, $c) = @_;

	if ($c->user_exists())
		{
		$c->response()->redirect($c->uri_for('/'));
		}
	else
		{
		$c->flash()->{return} = $c->uri_for($c->action());
		$c->detach('/login');
		}
	}

sub default :Path
	{
	my ( $self, $c ) = @_;

	$c->stash()->{template} = '404.tt';
	$c->response->status(404);
	}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
