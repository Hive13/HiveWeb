package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub lock :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};
	my $lock      = $c->stash()->{in}->{lock} // 1;
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member " . $member_id;
		return;
		}
	
	$out->{response} = \1;
	$out->{data}     = 'Member ' . ($lock ? 'locked out' : 'unlocked');
	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => $lock ? 'lock' : 'unlock',
				changing_member_id => $c->user()->member_id(),
				});
			$member->is_lockedout($lock);
			$member->update();
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update member.';
		};
	}

sub info :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	
	my @groups = $member->member_mgroups()->all();
	my @ogroups;
	foreach my $group (@groups)
		{
		my $g = $group->mgroup();
		push(@ogroups, { $g->get_inflated_columns() });
		}
	
	my @badges = $member->badges();
	my @obadges;
	foreach my $badge (@badges)
		{
		push(@obadges, { $badge->get_inflated_columns() });
		}
	$c->stash()->{out}->{badges}   = \@obadges;
	$c->stash()->{out}->{groups}   = \@ogroups;
	$c->stash()->{out}->{member}   = { $member->get_inflated_columns() };
	$c->stash()->{out}->{response} = JSON->true();
	}

sub add_badge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $member_id    = $c->stash()->{in}->{member_id};
	my $badge_number = $c->stash()->{in}->{badge_number};
	my $member       = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find member';
		return;
		}
	if (!defined($badge_number))
		{
		$out->{response} = \0;
		$out->{data}     = 'No badge specified';
		return;
		}
	
	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'add_badge',
				notes              => 'Badge number ' . $badge_number,
				changing_member_id => $c->user()->member_id(),
				});
			my $badge = $member->create_related('badges', { badge_number => $badge_number });
			$out->{badge_number} = $badge_number;
			$out->{badge_id}     = $badge->badge_id();
			$out->{response}     = \1;
			$out->{data}         = 'Badge created';
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update member.';
		};
	}

sub delete_badge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $member_id    = $c->stash()->{in}->{member_id};
	my $badge_ids    = $c->stash()->{in}->{badge_ids} // $c->stash()->{in}->{badge_id};
	my $member       = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find member';
		return;
		}
	if (!defined($badge_ids))
		{
		$out->{response} = \0;
		$out->{data}     = 'No badge specified';
		return;
		}
	
	$badge_ids = [ $badge_ids ]
		if (ref($badge_ids) ne 'ARRAY');
	
	$out->{response} = \1;
	$out->{data}     = "Badges deleted";
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $badge_id (@$badge_ids)
				{
				my $badge = $c->model('DB::Badge')->find($badge_id);
				die
					if (!defined($badge));
				$member->create_related('changed_audits',
					{
					change_type        => 'delete_badge',
					notes              => 'Badge number ' . $badge->badge_number(),
					changing_member_id => $c->user()->member_id(),
					});
				$badge->delete();
				}
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = "One or more badges was invalid";
		};
	}

sub password :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};
	my $password  = $c->stash()->{in}->{password};
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = JSON->false();
		$out->{data}     = "Cannot find member";
		return;
		}

	if (!$password)
		{
		$out->{response} = \0;
		$out->{data}     = 'Blank or invalid password supplied.';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'change_password',
				changing_member_id => $c->user()->member_id(),
				});
			$member->set_password($password);
			$out->{data}     = "Member password has been updated.";
			$out->{response} = \1;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not change password.';
		};
	}

sub edit :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	my $in  = $c->stash()->{in};
	my $out = $c->stash()->{out};

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$out->{response} = JSON->false();
		$out->{data}     = "Cannot find member";
		return;
		}
	my %new_groups   = map { $_ => 1; } @{$in->{groups}};
	my @groups       = $c->model('DB::MGroup')->all();
	if (exists($in->{vend_credits}))
		{
		my $vend_credits = int($in->{vend_credits});
		$member->update({ vend_credits => $vend_credits });
		}
	foreach my $group (@groups)
		{
		my $group_id = $group->mgroup_id();
		if ($new_groups{$group_id} && !$member->find_related('member_mgroups', { mgroup_id => $group_id }))
			{
			$c->log()->debug("Into " . $group->name());
			$member->create_related('member_mgroups', { mgroup_id => $group_id });
			}
		my $mg;
		if (!$new_groups{$group_id} && ($mg = $member->find_related('member_mgroups', { mgroup_id => $group_id })))
			{
			$c->log()->debug("Out of " . $group->name());
			$mg->delete();
			}
		}
	$out->{response} = JSON->true();
	$out->{data}     = "Member profile has been updated.";
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;
	
	$c->response->body('Matched HiveWeb::Controller::API in API.');
	}

=encoding utf8

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
