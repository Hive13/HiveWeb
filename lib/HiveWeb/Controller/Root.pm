package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub begin :Private
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

sub register :Local :Args(0)
	{
	my ($self, $c) = @_;
	return
		if ($c->request()->method() eq 'GET');

	my $message = $c->stash()->{message} = {};

	my $form = $c->request()->params();
	my $fail = 0;

	if (!$form->{email} || $form->{email} eq '' || $form->{email} !~ /.+@.+\..+/)
		{
		$message->{email} = "You must specify a valid e-mail address.";
		$fail = 1;
		}
	else
		{
		my $member = $c->model('DB::Member')->find({ email => $form->{email} });
		if ($member)
			{
			$message->{email} = 'That e-mail address has already been registered.';
			$fail = 1;
			}
		}
	if (!$form->{fname} || $form->{fname} eq '')
		{
		$message->{fname} = "You must specify your first name.";
		$fail = 1;
		}
	if (!$form->{lname} || $form->{lname} eq '')
		{
		$message->{lname} = "You must specify your last name.";
		$fail = 1;
		}

	if ($form->{password1} ne $form->{password2})
		{
		$message->{password} = "&lsaquo; The passwords don't match.";
		$fail = 1;
		}

	if ($fail)
		{
		$c->stash()->{vals} = $form;
		return;
		}

	my $password = $form->{password1};
	delete($form->{password1});
	delete($form->{password2});

	$c->model('DB')->schema()->txn_do(
	sub
		{
		my $member = $c->model('DB::Member')->create($form) || die $!;
		$member->set_password($password);
		my $user = $c->find_user({ member_id => $member->member_id() });
		$c->set_authenticated($user);
		});

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
