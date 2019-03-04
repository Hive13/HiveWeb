package HiveWeb::Controller::API::Panel;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;
	}

sub hide :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $in      = $c->stash()->{in};
	my $panel   = $c->model('DB::Panel')->find($in->{panel_id}) || return;

	$c->model('DB')->txn_do(sub
		{
		my $mp = $panel->find_or_create_related('member_panels',
			{
			member_id => $c->user()->member_id(),
			visible   => 'f',
			}) || die $!;
		});

	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
