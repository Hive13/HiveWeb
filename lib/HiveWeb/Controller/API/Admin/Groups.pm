package HiveWeb::Controller::API::Admin::Groups;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub info :Local :Args(1)
	{
	my ($self, $c, $group_id) = @_;

	my $group = $c->model('DB::MGroup')->find($group_id);
	if (!defined($group))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}
	
	my @mgs = $group->member_mgroups()->all();
	my @omembers;
	foreach my $mg (@mgs)
		{
		my $m = $mg->member();
		push(@omembers, { $m->get_inflated_columns() });
		}
	
	$c->stash()->{out}->{members}  = \@omembers;
	$c->stash()->{out}->{group}    = { $group->get_inflated_columns() };
	$c->stash()->{out}->{response} = JSON->true();
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
