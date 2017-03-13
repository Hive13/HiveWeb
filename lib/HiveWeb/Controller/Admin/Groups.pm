package HiveWeb::Controller::Admin::Groups;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my $self  = shift;
	my $c     = shift;

	$c->response()->redirect($c->uri_for('/admin/groups/view'));
	}

sub view :Local
	{
	my $self  = shift;
	my $c     = shift;
	my $order = shift // "name";
	my $dir   = uc(shift // "ASC");

	$dir = "ASC"
		if ($dir ne "ASC" && $dir ne "DESC");
	my $sorder .= "$order $dir";

	my @groups = $c->model('DB::MGroup')->search({}, {order_by => $sorder});
	my @members  = $c->model('DB::Member')->search({});

	$c->stash()->{groups}   = \@groups;
	$c->stash()->{members}  = \@members;
	$c->stash()->{order}    = $order;
	$c->stash()->{dir}      = $dir;
	$c->stash()->{template} = 'admin/groups/index.tt';
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
