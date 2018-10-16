package HiveWeb::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private
	{
	my ($self, $c) = @_;

	if (lc($c->req()->content_type()) eq 'multipart/form-data')
		{
		$c->stash()->{in} = $c->req()->body_parameters();
		}
	else
		{
		$c->stash()->{in} = $c->req()->body_data();
		}
	$c->stash()->{out} = { response => \0 };
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

__PACKAGE__->meta->make_immutable;

1;
