package HiveWeb::Controller::Storage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	}

sub request :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'storage/request.tt';

	return
		if ($c->request()->method() eq 'GET');

	my $form    = $c->request()->params();
	my $request = $c->user->create_related('requests',
		{
		notes => $form->{notes}
		}) || die $!;
	$c->response()->redirect($c->uri_for('/'));
	}


=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
