package HiveWeb::Controller::API::Soda;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('status');
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};
	my @sodas      = $c->model('DB::SodaStatus')->all();

	$out->{response} = \1;
	$out->{sodas}    = \@sodas;
	}

__PACKAGE__->meta->make_immutable;

1;
