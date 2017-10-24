package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auto :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{extra_css} = [];
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'index.tt'; 
	}

sub login :Local
	{
	my ($self, $c) = @_;

	if ($c->request()->method() eq 'GET')
		{
		$c->stash()->{template} = 'login.tt'; 
		return;
		}
	
	my $params = $c->request()->params();

	my $auth          = {};
	$auth->{email}    = $params->{email};
	$auth->{password} = $params->{password};
	my $user = $c->authenticate($auth);
	my $log  = $c->model('DB::SignInLog')->create(
		{
		email     => $params->{email},
		valid     => $user ? 1 : 0,
		member_id => $user ? $user->member_id() : undef,
		remote_ip => $c->request()->address(),
		}) || die $!;
	if ($user)
		{
		$c->response()->redirect($c->uri_for('/'));
		}
	else
		{
		$c->stash()->{template} = 'login.tt'; 
		$c->stash()->{msg} = 'The username or password were invalid.'; 
		$c->response->status(403);
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
	
	$c->stash()->{template} = '404.tt';
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
