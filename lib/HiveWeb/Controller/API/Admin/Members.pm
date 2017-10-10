package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub lock :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	$member_id //= $c->stash()->{in}->{member_id};
	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	
	$member->is_lockedout(1);
	$member->update();
	$c->stash()->{out}->{response} = JSON->true();
	$c->stash()->{out}->{data}     = "Member locked out";
	}

sub unlock :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	$member_id //= $c->stash()->{in}->{member_id};
	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	
	$member->is_lockedout(0);
	$member->update();
	$c->stash()->{out}->{response} = JSON->true();
	$c->stash()->{out}->{data}     = "Member unlocked";
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

sub add_badge :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;
	my $badge_number = $c->stash()->{in}->{badge_number};

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	if (!defined($badge_number))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "No badge specified";
		return;
		}
	
	my $badge = $member->create_related('badges', { badge_number => $badge_number });
	$c->stash()->{out}->{badge_number} = $badge_number;
	$c->stash()->{out}->{badge_id} = $badge->badge_id();
	$c->stash()->{out}->{response} = JSON->true();
	$c->stash()->{out}->{data}     = "Badge created";
	}

sub delete_badge :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;
	my $badge_ids = $c->stash()->{in}->{badge_ids} // $c->stash()->{in}->{badge_id};

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	if (!defined($badge_ids))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "No badge specified";
		return;
		}
	
	$badge_ids = [ $badge_ids ]
		if (ref($badge_ids) ne 'ARRAY');
	
	$c->stash()->{out}->{response} = JSON->true();
	$c->stash()->{out}->{data}     = "Badges deleted";
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $badge_id (@$badge_ids)
				{
				my $badge = $c->model('DB::Badge')->find($badge_id);
				die
					if (!defined($badge));
				$badge->delete();
				}
			});
		}
	catch
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "One or more badges was invalid";
		return;
		};
	}

sub edit :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	my %new_groups   = map { $_ => 1; } @{$c->stash()->{in}->{groups}};
	my @groups       = $c->model('DB::MGroup')->all();
	my $vend_credits = int($c->stash()->{in}->{vend_credits}) || $member->vend_credits();
	$member->update({ vend_credits => $vend_credits });
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
	$c->stash()->{out}->{response} = JSON->true();
	$c->stash()->{out}->{data}     = "Member profile has been updated.";
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
