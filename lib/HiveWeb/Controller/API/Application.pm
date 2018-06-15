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

	$out->{has_picture}    = $application->picture_id()       ? \1 : \0;
	$out->{has_form}       = $application->form_id()          ? \1 : \0;
	$out->{submitted_form} = $application->app_turned_in_at() ? \1 : \0;
	$out->{response}       = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
