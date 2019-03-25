package HiveWeb::Controller::API::Admin::Storage::Slot;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('info');
	}

sub info :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $slot_id = $in->{slot_id};

	$out->{data}     = 'Cannot find slot.';

	my $slot = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id }) || return;
	my $logs = $c->model('DB::AuditLog')->search({ notes => { ilike => "%$slot_id%" } }) || die $!;

	$out->{slot}     = $slot->TO_FULL_JSON();
	$out->{logs}     = [ $logs->all() ];
	$out->{response} = \1;
	delete($out->{data});
	}

sub edit :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in          = $c->stash()->{in};
	my $out         = $c->stash()->{out};
	my $name        = $in->{name};
	my $location_id = $in->{location_id};
	my $slot_id     = $in->{slot_id};
	my $type_id     = $in->{type_id};
	my $data        = {};
	my $slot;

	$out->{data} = $slot_id ? 'Could not edit slot.' : 'Could not add slot.';

	if (!$location_id && !$slot_id)
		{
		$out->{data} = 'You must provide either a slot or a location.';
		return;
		}
	if (!$slot_id && (!$name || !$type_id))
		{
		$out->{data} = 'You must provide a name and type for a new slot.';
		return;
		}
	if ($slot_id && !($slot = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id })))
		{
		$out->{data} = 'Invalid slot specified.';
		return;
		}
	if ($location_id && !($c->model('DB::StorageLocation')->find({ location_id => $location_id })))
		{
		$out->{data} = 'Invalid parent specified.';
		return;
		}
	if ($type_id && !($c->model('DB::StorageSlotType')->find($type_id)))
		{
		$out->{data} = 'Invalid type specified.';
		return;
		}

	$data->{name}        = $name
		if ($name);
	$data->{sort_order}  = int($in->{sort_order})
		if (exists($in->{sort_order}) && defined($in->{sort_order}));
	$data->{location_id} = $location_id
		if ($location_id);
	$data->{type_id} = $type_id
		if ($type_id);

	if ($slot)
		{
		$slot->update($data) || die $!;
		$out->{data} = 'Slot updated.';
		}
	else
		{
		$slot        = $c->model('DB::StorageSlot')->create($data) || die $!;
		$out->{data} = 'Slot added.';
		}
	$out->{response} = \1;
	$out->{slot_id}  = $slot->slot_id();
	}

sub delete :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $slot_id = $in->{slot_id};
	my $slot;

	$out->{data} = 'Could not delete slot.';

	if (!$slot_id || !($slot = $c->model('DB::StorageSlot')->find($slot_id)))
		{
		$out->{data} = 'Invalid slot specified.';
		return;
		}

	$slot->delete() || die $!;
	$out->{data} = 'Slot deleted.';
	$out->{response} = \1;
	}

sub assign :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $slot_id   = $in->{slot_id};
	my $member_id = $in->{member_id};
	my $slot      = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id });
	my $member;

	$out->{data} = 'Could not assign slot.';
	if (!$slot)
		{
		$out->{data} = 'You must provide a valid slot.';
		return;
		}
	if (!exists($in->{member_id}))
		{
		$out->{data} = 'You must provide a member_id field.';
		return;
		}

	if ($member_id)
		{
		$member = $c->model('DB::Member')->find({ member_id => $member_id });
		if (!$member)
			{
			$out->{data} = 'You must provide a valid member.';
			return;
			}
		}
	else
		{
		$member_id = undef;
		}
	
	$out->{response} = \1;
	$out->{data}     = 'Slot updated.';
	#try
	#	{
		$slot->update({ member_id => $member_id });
	#	}
	#catch
	#	{
	#	$out->{response} = \0;
	#	$out->{data}     = 'Could not update slot.';
	#	};
	}

__PACKAGE__->meta->make_immutable;

1;
