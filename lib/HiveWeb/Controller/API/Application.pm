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
	$out->{response} = \0;

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
	$out->{response} = \1;
	$out->{data}     = 'Application marked as submitted.';

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$application->update({ app_turned_in_at => \'current_timestamp' });
			$c->model('DB')->resultset('Action')->create(
				{
				queuing_member_id => $c->user()->member_id(),
				action_type       => 'application.mark_submitted',
				row_id            => $application->application_id(),
				}) || die 'Could not queue notification: ' . $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not mark application as submitted: ' . $_;
		};
	}

sub attach_picture :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	my $application  = $c->stash()->{application};
	$out->{response} = \1;

	my $image = $c->model('DB::Image')->find($in->{image_id});
	if (!$image || !$image->can_view($c->user()))
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find that image.';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $priority = $c->config()->{priorities}->{'application.attach_picture'};
			$application->update({ picture_id => $image->image_id() }) || die $!;
			$c->model('DB::Action')->create(
				{
				queuing_member_id => $c->user()->member_id(),
				priority          => $priority,
				action_type       => 'application.attach_picture',
				row_id            => $application->application_id(),
				}) || die 'Could not queue notification: ' . $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not attach picture: ' . $_;
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

	$out->{response} = \1;
	$out->{data}     = 'The scanned form has been attached to the application.';

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$application->update({ form_id => $image->image_id() }) || die $!;
			$c->model('DB::Action')->create(
				{
				queuing_member_id => $c->user()->member_id(),
				action_type       => 'application.attach_form',
				row_id            => $application->application_id(),
				}) || die 'Could not queue notification: ' . $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not attach the form to the application: ' . $_;
		};
	}

__PACKAGE__->meta->make_immutable;

1;
