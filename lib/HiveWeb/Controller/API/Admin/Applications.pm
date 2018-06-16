package HiveWeb::Controller::API::Admin::Applications;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub pending :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	$out->{response} = \0;

	my @pending_applications = $c->model('DB::Application')->search({})->all();

	$out->{response} = \1;
	$out->{app_info} = \@pending_applications;
	}

__PACKAGE__->meta->make_immutable;

1;
