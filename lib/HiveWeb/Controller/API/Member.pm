package HiveWeb::Controller::API::Member;
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON::MaybeXS;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('find');
	}

sub find :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
	my $member;

	if ($in->{badge})
		{
		my $badge = $c->model('DB::Badge')->find({ badge_number => $in->{badge} });
		$member = $badge->member()
			if ($badge);
		}
	elsif (my $id = ($in->{member_id} // $in->{id}))
		{
		$member = $c->model('DB::Member')->find({ member_id => $id });
		}

	if (!$member)
		{
		$out->{error} = 'Cannot find user.';
		return;
		}
	$out->{response} = \1;
	$out->{member}   =
		{
		fname  => $member->fname(),
		lname  => $member->lname(),
		handle => $member->handle(),
		};
	}

sub two_factor :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
	my $user       = $c->user();
	my $enable     = $in->{enable} // 1;

	return if (!$user);

	if ($enable)
		{
		my $secret = $c->session()->{candidate_secret};
		my $code   = $in->{code};
		if (!$secret)
			{
			$out->{data} = 'Cannot find secret.';
			return;
			}

		if (!$user->check_2fa($code, $secret))
			{
			$out->{data} = 'That code does not work.  Please try again.';
			return;
			}

		$user->update({ totp_secret => $secret }) || die $!;
		$out->{response} = \1;
		$out->{data}     = 'Two-Factor Authentication has been enabled on your account.';
		}
	else
		{
		$user->update({ totp_secret => undef }) || die $!;
		$out->{response} = \1;
		$out->{data}     = 'Two-Factor Authentication has been disabled on your account.';
		}
	}

sub soda :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in   = $c->stash()->{in};
	my $out  = $c->stash()->{out};
	my $user = $c->user();

	if ($c->request()->method() eq 'POST')
		{
		my $alerts  = $in->{alerts};
		if (ref($alerts) eq 'HASH')
			{
			$c->user()->update(
				{
				alert_credits => $alerts->{credits},
				alert_email   => $alerts->{email},
				alert_machine => $alerts->{machine},
				});
			$out->{alerts} =
				{
				credits => $alerts->{credits},
				email   => $alerts->{email} ? \1 : \0,
				machine => $alerts->{machine} ? \1 : \0,
				};
			}
		else
			{
			$c->user()->update({ alert_credits => undef });
			$out->{alerts} = undef;
			}
		$out->{response} = \1;
		return;
		}

	if (defined($user->alert_credits()))
		{
		$out->{alerts} =
			{
			credits => $user->alert_credits(),
			email   => $user->alert_email() ? \1 : \0,
			machine => $user->alert_machine() ? \1 : \0,
			};
		}
	else
		{
		$out->{alerts} = undef;
		}
	$out->{credits}  = $user->vend_credits();
	$out->{config}   = $c->config()->{soda};
	$out->{key}      = $c->config()->{stripe}->{public_key};
	$out->{response} = \1;
	}

sub charge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $config  = $c->config();
	my $credits = $config->{soda}->{add_amount};

	my $ua  = LWP::UserAgent->new();

	my $data =
		{
		amount      => $config->{soda}->{cost},
		currency    => 'usd',
		description => $credits . ' Hive Soda Credits',
		source      => $in->{token},
		};
	my $req = POST 'https://api.stripe.com/v1/charges', $data || die $!;
	$req->header(Authorization => 'Bearer ' . $c->config()->{stripe}->{secret_key});
	my $res = $ua->request($req);

	my $stripe = decode_json($res->content());
	if ($res->code() == 200)
		{
		$c->user()->add_vend_credits($credits);
		}
	else
		{
		$out->{error} = $stripe->{error}->{error};
		if ($out->{error} eq 'card_declined')
			{
			$out->{message} = $stripe->{error}->{message};
			}
		}
	$out->{response} = \1;
	$out->{success}  = (($res->code() == 200) ? \1 : \0);
	}

sub slack_invite :Local
	{
	my ($self, $c) = @_;

	my $out    = $c->stash()->{out};
	my $config = $c->config();
	my $member = $c->user();

	my $slack_invite =
		{
		first_name => $member->fname(),
		last_name  => $member->lname(),
		channels   => join(',', @{ $config->{slack}->{channels} }),
		email      => $member->email(),
		token      => $config->{slack}->{token},
		};

	$out->{response} = \1;
	my $ua = LWP::UserAgent->new();
	$ua->agent(sprintf('HiveWeb/%s (%s)', $HiveWeb::VERSION, $ua->agent));
	my $response = $ua->post($config->{slack}->{api}, $slack_invite);
	my $slack_result = decode_json($response->content());
	my $schema = $c->model('DB');
	if (!$slack_result->{ok})
		{
		$schema->resultset('Log')->new_log(
			{
			type    => 'slack.invite_error',
			message => 'Cannot invite ' . $member->member_id() . ' to Slack: ' . $slack_result->{error}
			});
		$out->{response} = \0;
		$out->{data}     = 'Could not send a Slack invite.';
		}
	}

__PACKAGE__->meta->make_immutable;

1;
