package HiveWeb::Controller::API::Storage;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('list');
	}

sub list :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};

	my $user     = $c->user() || return;
	my @slots    = $user->list_slots();
	my @requests = $user->requests()->search(
		{
		hidden  => 'f',
		type_id => { '!=' => undef },
		})->all();

	$out->{slots}    = \@slots;
	$out->{requests} = \@requests;
	$out->{response} = \1;
	}

sub requests :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	my $user         = $c->user() || return;
	$out->{requests} = [ $user->requests()->search({}, { order_by => { -desc => 'created_at' } })->all() ];
	$out->{response} = \1;
	}

sub types :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};

	$out->{types}    = [ $c->model('DB::StorageSlotType')->search({ can_request => 't' })->all() ];
	$out->{response} = \1;
	}

sub request :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};
	my $in         = $c->stash()->{in};

	if (exists($in->{slot_id}))
		{
		my $slot = $c->model('DB::StorageSlot')->find($in->{slot_id});
		if (!$slot)
			{
			$out->{data} = 'Invalid Slot ID';
			return;
			}
		if ($slot->member_id() && $slot->member_id() ne $c->user()->member_id())
			{
			$out->{data} = 'This slot does not belong to you.';
			return;
			}
		}
	my $request = $c->user->create_related('requests',
		{
		notes   => $in->{notes},
		type_id => $in->{type_id},
		slot_id => $in->{slot_id},
		}) || die $!;
	$out->{response}   = \1;
	$out->{request_id} = $request->request_id();
	}
sub relinquish :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in   = $c->stash()->{in};
	my $out  = $c->stash()->{out};
	my $user = $c->user() || return;

	my $slot = $c->model('DB::StorageSlot')->find($in->{slot_id});
	if (!$slot)
		{
		$out->{data} = "Could not find slot \"$in->{slot_id}\".";
		return;
		}
	if ($slot->member_id() ne $c->user()->member_id())
		{
		$out->{data} = 'This slot does not belong to you.';
		return;
		}

	try
		{
		$slot->update({ member_id => undef }) || die $!;
		$out->{response} = \1;
		}
	catch
		{
		$out->{data} = 'Could not relinquish slot.';
		};
	}

sub hide :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in   = $c->stash()->{in};
	my $out  = $c->stash()->{out};
	my $user = $c->user() || return;

	my $request = $c->model('DB::StorageRequest')->find($in->{request_id});
	if (!$request)
		{
		$out->{data} = "Could not find request \"$in->{request_id}\".";
		return;
		}
	if ($request->member_id() ne $c->user()->member_id())
		{
		$out->{data} = 'This request does not belong to you.';
		return;
		}
	if ($request->status() ne 'accepted' && $request->status() ne 'rejected')
		{
		$out->{data} = 'This request has not been finalized.';
		return;
		}

	try
		{
		$request->update({ hidden => 't' }) || die $!;
		$out->{response} = \1;
		}
	catch
		{
		$out->{data} = 'Could not relinquish slot.';
		};
	}

__PACKAGE__->meta->make_immutable;

1;
