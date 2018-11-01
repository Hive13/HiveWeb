package HiveWeb::Controller::API::Curse;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('list');
	}

sub list :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out  = $c->stash()->{out};
	my $user = $c->user() || return;

	my @curses = $user->search_related('member_curses',
		{
		lifted_at => undef,
		},
		{
		order_by => [ 'priority', 'issued_at' ],
		prefetch => { issuing_member => 'member_mgroups', curse => 'curse_actions' },
		});

	$out->{curses}   = \@curses;
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
