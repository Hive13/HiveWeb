package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Net::SMTP;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auto :Private
	{
	my ($self, $c) = @_;

	my $toast = $c->stash()->{auto_toast} = [];

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

sub login :Local
	{
	my ($self, $c) = @_;

	if ($c->request()->method() eq 'GET')
		{
		$c->stash()->{template} = 'login.tt';
		return;
		}
	
	my $params = $c->request()->params();

	my $auth          = {};
	$auth->{email}    = $params->{email};
	$auth->{password} = $params->{password};
	my $user = $c->authenticate($auth);
	my $log  = $c->model('DB::SignInLog')->create(
		{
		email     => $params->{email},
		valid     => $user ? 1 : 0,
		member_id => $user ? $user->member_id() : undef,
		remote_ip => $c->request()->address(),
		}) || die $!;
	if ($user)
		{
		$c->response()->redirect($c->uri_for('/'));
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
		$c->log()->debug('Sending mail.');

		my $config = $c->config()->{email};
		my $forgot = $config->{forgot};
		my $token  = $member->create_related('reset_tokens', { valid => 1 });
		my $to     = $member->email();
		my $from   = $config->{from};
		my $stash  =
			{
			token  => $token,
			member => $member,
			};

		my $body = $c->view('TT')->render($c, $forgot->{temp_plain}, $stash);

		my $smtp = Net::SMTP->new(%{$config->{'Net::SMTP'}});
		die "Could not connect to server\n"
			if !$smtp;

		if (exists($config->{auth}))
			{
			$smtp->auth($from, $config->{auth})
				|| die "Authentication failed!\n";
			}

		$smtp->mail('<' . $from . ">\n");
		$smtp->to('<' . $to . ">\n");
		$smtp->data();
		$smtp->datasend('From: "' . $config->{from_name} . '" <' . $from . ">\n");
		$smtp->datasend('To: "' . $member->fname() . ' ' . $member->lname() . '" <' . $to . ">\n");
		$smtp->datasend('Subject: ' . $forgot->{subject} . "\n");
		$smtp->datasend("\n");
		$smtp->datasend($body . "\n");
		$smtp->dataend();
		$smtp->quit();
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

sub default :Path
	{
	my ( $self, $c ) = @_;
	
	$c->stash()->{template} = '404.tt';
	$c->response->status(404);
	}

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
