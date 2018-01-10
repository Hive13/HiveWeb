package HiveWeb::Controller::API::Admin::Storage;
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
	$out->{response} = \0;

	my $root_location = $c->model('DB::StorageLocation')->find({ parent_id => undef }) || die $!;
	my $request_count = $c->model('DB::StorageRequest')->count();

	$out->{locations} = $root_location;
	$out->{requests}  = $request_count;
	$out->{response}  = \1;
	}

sub info :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $slot_id = $in->{slot_id};

	$out->{response} = \0;
	$out->{data}     = 'Cannot find slot.';

	my $slot = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id }) || return;

	$out->{slot}      = $slot->TO_FULL_JSON();
	$out->{response}  = \1;
	delete($out->{data});
	}

sub edit_slot :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in          = $c->stash()->{in};
	my $out         = $c->stash()->{out};
	my $name        = $in->{name};
	my $location_id = $in->{location_id};
	my $slot_id     = $in->{slot_id};
	my $location;
	my $slot;

	$out->{response} = \0;
	$out->{data}     = $slot_id ? 'Could not add slot.' : 'Could not add slot.';

	if (!$location_id && !$slot_id)
		{
		$out->{data} = 'You must provide either a slot or a location.';
		return;
		}
	if (!$name)
		{
		$out->{data} = 'You must provide a name.';
		return;
		}
	if ($slot_id && !($slot = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id })))
		{
		$out->{data} = 'Invalid slot specified.';
		return;
		}
	if ($location_id && !($location = $c->model('DB::StorageLocation')->find({ location_id => $location_id })))
		{
		$out->{data} = 'Invalid parent specified.';
		return;
		}

	if ($slot)
		{
		my $data = { name => $name };
		$data->{location_id} = $location_id
			if ($location);
		$slot->update($data) || die $!;
		$out->{data} = 'Slot updated.';
		}
	else
		{
		$slot        = $c->model('DB::StorageSlot')->create({ name => $name, location_id => $location_id }) || die $!;
		$out->{data} = 'Slot added.';
		}
	$out->{response} = \1;
	$out->{slot_id}  = $slot->slot_id();
	}

sub new_location :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $name      = $in->{name};
	my $parent_id = $in->{parent_id};
	my $parent;

	$out->{response} = \0;
	$out->{data}     = 'Could not add location.';
	if (!$name)
		{
		$out->{data} = 'You must provide a name.';
		return;
		}
	if (!$parent_id)
		{
		$out->{data} = 'You must provide a parent location.';
		return;
		}
	elsif (!($parent = $c->model('DB::StorageLocation')->find({ location_id => $parent_id })))
		{
		$out->{data} = 'Invalid parent specified.';
		return;
		}

	my $location = $c->model('DB::StorageLocation')->create({ name => $name, parent_id => $parent_id }) || die $!;
	$out->{response}     = \1;
	$out->{data}         = 'Location added.';
	$out->{location_id}  = $location->location_id();
	}

sub assign_slot :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $slot_id   = $in->{slot_id};
	my $member_id = $in->{member_id};
	my $slot      = $c->model('DB::StorageSlot')->find({ slot_id => $slot_id });
	my $member;

	$out->{response} = \0;
	$out->{data}     = 'Could not assign slot.';
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

	if (!$slot->member_id())
		{
		$member = $c->model('DB::Member')->find({ member_id => $member_id });
		if (!$member)
			{
			$out->{data} = 'You must provide a valid member.';
			return;
			}
		}
	elsif (!$member_id)
		{
		$out->{response} = \1;
		$out->{data}     = 'Slot unassigned.';
		try
			{
			$c->model('DB')->txn_do(sub
				{
				$slot->member()->create_related('changed_audits',
					{
					change_type        => 'unassign_slot',
					notes              => 'Unassigned slot ' . $slot_id,
					changing_member_id => $c->user()->member_id(),
					}) || die $!;
				$slot->update({ member_id => undef }) || die $!;
				});
			}
		catch
			{
			$out->{response} = \0;
			$out->{data}     = 'Could not unassign slot.';
			};
		return;
		}

	$out->{response} = \1;
	$out->{data}     = 'Slot assigned.';

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'assign_slot',
				notes              => 'Assigned slot ' . $slot_id,
				changing_member_id => $c->user()->member_id(),
				});
			$slot->update({ member_id => $member_id }) || die $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not assign slot.';
		};
	}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
