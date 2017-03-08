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
