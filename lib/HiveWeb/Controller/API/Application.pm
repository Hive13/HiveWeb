package HiveWeb::Controller::API::Application;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub auto :Private
	{
	my ($self, $c)   = @_;
	my $in           = $c->stash()->{in};
	my $out          = $c->stash()->{out};
	my $user         = $c->user();

	return if (!$user);

	my $application = $in->{application_id} ?
		$c->model('DB::Application')->find($in->{application_id}) :
		$user->find_related('applications',
			{
			decided_at => undef,
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

	if (!$application || ($application->member_id() ne $user->member_id() && !$c->check_user_roles('board')))
		{
		$out->{data} = 'Cannot find application.';
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

	try
		{
		$application->update({ app_turned_in_at => \'current_timestamp' });
		$out->{response} = \1;
		$out->{data}     = 'Application marked as submitted.';
		}
	catch
		{
		$out->{data} = 'Could not mark application as submitted: ' . $_;
		};
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
		$out->{data} = 'Cannot find that image.';
		return;
		}

	try
		{
		$application->update({ picture_id => $image->image_id() }) || die $!;
		$out->{response} = \1;
		$out->{data}     = 'Picture attached to application.';
		}
	catch
		{
		$out->{data} = 'Could not attach picture: ' . $_;
		};
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

	try
		{
		$application->update({ form_id => $image->image_id() }) || die $!;
		$out->{response} = \1;
		$out->{data}     = 'The scanned form has been attached to the application.';
		}
	catch
		{
		$out->{data} = 'Could not attach the form to the application: ' . $_;
		};
	}

__PACKAGE__->meta->make_immutable;

1;
