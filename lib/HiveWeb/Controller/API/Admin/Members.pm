package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;

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

	$c->log()->debug(Data::Dumper::Dumper($c->stash()->{in}));

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

sub begin :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{in} = $c->req()->body_data();
	$c->stash()->{out} = {};
	$c->stash()->{view} = $c->view('JSON');
	}

sub end :Private
	{
	my ($self, $c) = @_;

	$c->detach($c->stash()->{view});
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
