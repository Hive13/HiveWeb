package HiveWeb::Controller::API::Application;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('status');
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};
	$out->{response} = \0;

	my $user     = $c->user() || return;
	my $application = $user->find_related('applications', {},
		{
		order_by => { -desc => 'updated_at' },
		rows     => 1,
		}) || return;

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
	my $in           = $c->stash()->{in};
	$out->{response} = \0;
	my $user         = $c->user() || return;

	my $application = $c->model('DB::Application')->find($in->{application_id});
	if (!$application || $application->member_id() ne $user->member_id())
		{
		$out->{response} = 'Cannot find that application.';
		return;
		}

	$application->update({ app_turned_in_at => \'current_timestamp' });
	$out->{response} = \1;
	}

sub attach_picture :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	$out->{response} = \0;
	my $user         = $c->user() || return;

	my $application = $c->model('DB::Application')->find($in->{application_id});
	if (!$application || $application->member_id() ne $user->member_id())
		{
		$out->{response} = 'Cannot find that application.';
		return;
		}

	my $image = $c->model('DB::Image')->find($in->{image_id});
	if (!$image || !$image->can_view($user))
		{
		$out->{response} = 'Cannot find that image.';
		return;
		}

	$application->update({ picture_id => $image->image_id() });
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
