package HiveWeb::Controller::API::Member;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub auto :Private
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	$out->{response} = \0;
	}

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
		$out->{response} = \0;
		$out->{error}    = 'Cannot find user.';
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

__PACKAGE__->meta->make_immutable;

1;
