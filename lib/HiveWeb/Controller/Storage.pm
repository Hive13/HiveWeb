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

	my @types = $c->model('DB::StorageSlotType')->search({ can_request => 't' });
	$c->stash()->{types} = \@types;

	return
		if ($c->request()->method() eq 'GET');

	my $form    = $c->request()->params();
	my $request = $c->user->create_related('requests',
		{
		notes   => $form->{notes},
		type_id => $form->{type_id},
		}) || die $!;
	$c->response()->redirect($c->uri_for('/'));
	}

__PACKAGE__->meta->make_immutable;

1;
