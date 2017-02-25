package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;
	
	$c->stash()->{template} = 'index.tt'; 
	}

sub login :Local
	{
	my ($self, $c) = @_;
	my $params = $c->request()->params();

	my $auth          = {};
	$auth->{email}    = $params->{email};
	$auth->{password} = $params->{password};
	my $user = $c->authenticate($auth);
	$c->log()->debug(Dumper($user));
	if ($user)
		{
		$c->response()->redirect($c->uri_for('/'));
		}
	else
		{
		$c->response()->body('Nope.');
		}
	}

sub logout :Local
	{
	my ($self, $c) = @_;

	$c->logout();
	$c->response()->redirect($c->uri_for('/'));
	}

sub default :Path
	{
	my ( $self, $c ) = @_;
	
	$c->response->body('Page not found');
	$c->response->status(404);
	}

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
