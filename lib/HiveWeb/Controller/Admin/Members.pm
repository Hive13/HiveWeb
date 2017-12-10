package HiveWeb::Controller::Admin::Members;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my $self  = shift;
	my $c     = shift;

	$c->response()->redirect($c->uri_for('/admin/members/view'));
	}

sub view :Local
	{
	my $self  = shift;
	my $c     = shift;

	$c->stash()->{template} = 'admin/members/index.tt';
	}

=encoding utf8

=head1 AUTHOR

Greg Arnold,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
