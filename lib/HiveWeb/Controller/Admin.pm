package HiveWeb::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'admin/index.tt';
	}

sub storage :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->session()->{storage_table} //=
		{
		page     => 1,
		per_page => 50,
		};

	my @types = $c->model('DB::StorageSlotType')->all();
	$c->stash(
		{
		types    => \@types,
		template => 'admin/storage.tt',
		});
	}

sub access_log :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->session()->{access_log_table} //=
		{
		page     => 1,
		per_page => 50,
		};

	$c->stash()->{template} = 'admin/access_log.tt';
	}

sub members :Local
	{
	my $self  = shift;
	my $c     = shift;

	$c->session()->{member_table} //=
		{
		page     => 1,
		per_page => 50,
		};

	$c->stash()->{template} = 'admin/members.tt';
	}

sub curses :Local
	{
	my $self = shift;
	my $c    = shift;

	$c->session()->{curse_table} //=
		{
		page     => 1,
		per_page => 50,
		};

	$c->stash()->{template} = 'admin/curses.tt';
	}

__PACKAGE__->meta->make_immutable;

1;
