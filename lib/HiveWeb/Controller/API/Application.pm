package HiveWeb::Controller::API::Application;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub auto :Private
	{
	my ($self, $c)   = @_;
	my $in           = $c->stash()->{in};
	my $out          = $c->stash()->{out};
	my $user         = $c->user();
	$out->{response} = \0;

	return if (!$user);

	my $application = $in->{application_id} ?
		$c->model('DB::Application')->find($in->{application_id}) :
		$user->find_related('applications', {},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

	if (!$application || ($application->member_id() ne $user->member_id() && !$c->check_user_roles('board')))
		{
		$out->{response} = 'Cannot find application.';
		return;
		}

	$c->stash({ application => $application });
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('status');
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};

	my $application = $c->stash()->{application};

	$out->{has_picture}       = $application->picture_id()       ? \1 : \0;
	$out->{has_form}          = $application->form_id()          ? \1 : \0;
	$out->{submitted_form_at} = $application->app_turned_in_at() || \0;
	$out->{application_id}    = $application->application_id();
	$out->{response}          = \1;
	}

sub submit :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $application  = $c->stash()->{application};

	$application->update({ app_turned_in_at => \'current_timestamp' });
	$out->{response} = \1;
	}

sub attach_picture :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	my $application  = $c->stash()->{application};

	my $image = $c->model('DB::Image')->find($in->{image_id});
	if (!$image || !$image->can_view($c->user()))
		{
		$out->{response} = 'Cannot find that image.';
		return;
		}

	$application->update({ picture_id => $image->image_id() });
	$out->{response} = \1;
	}

sub attach_form :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	my $application  = $c->stash()->{application};

	my $image = $c->model('DB::Image')->find($in->{image_id});
	if (!$image || !$image->can_view($c->user()))
		{
		$out->{response} = 'Cannot find that image.';
		return;
		}

	$application->update({ form_id => $image->image_id() });
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
