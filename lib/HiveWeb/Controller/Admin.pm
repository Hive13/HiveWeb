package HiveWeb::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private
	{
	my ($self, $c) = @_;

	push (@{$c->stash()->{extra_css}}, $c->uri_for('/static/css/admin.css'));
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;
	
	$c->stash()->{template} = 'admin/index.tt';
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
