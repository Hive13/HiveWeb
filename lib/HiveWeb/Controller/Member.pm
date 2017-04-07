package HiveWeb::Controller::Member;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub verify_user_data
	{
	my ($self, $c, $form, $has_pass) = @_;

	my $message = {};
	my $fail    = 0;

	if (!$form->{email} || $form->{email} eq '' || $form->{email} !~ /.+@.+\..+/)
		{
		$message->{email} = "You must specify a valid e-mail address.";
		$fail = 1;
		}
	else
		{
		my $search = { email => $form->{email} };
		$search->{member_id} = { '!=' => $c->user()->member_id() }
			if ($c->user());
		my $member = $c->model('DB::Member')->search($search);
		if ($member->count())
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

	if ($has_pass && $form->{password1} ne $form->{password2})
		{
		$message->{password} = "&lsaquo; The passwords don't match.";
		$fail = 1;
		}

	return ($fail, $message);
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('profile');
	}

sub profile :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'member/profile.tt';
	
	return
		if ($c->request()->method() eq 'GET');

	my $form = $c->request()->params();
	my $fail;
	($fail, $c->stash()->{message}) = $self->verify_user_data($c, $form, 0);
	
	if ($fail)
		{
		$c->stash()->{vals} = $form;
		return;
		}
		
	$c->user()->update($form) || die $!;
	$c->response()->redirect($c->uri_for('/'));
	}

sub register :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'member/profile.tt';
	
	return
		if ($c->request()->method() eq 'GET');

	my $form = $c->request()->params();
	my $fail;
	($fail, $c->stash()->{message}) = $self->verify_user_data($c, $form, 1);

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

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
