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
	my $request_count = $c->model('DB::StorageRequest')->search({ status => { not_in => ['accepted', 'rejected'] } })->count();

	$out->{locations} = $root_location->TO_FULL_JSON();
	$out->{requests}  = $request_count;
	$out->{response}  = \1;
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};
	$out->{response} = \0;

	my $request_count   = $c->model('DB::StorageRequest')->search({ status => { not_in => ['accepted', 'rejected'] } })->count();
	my $available_slots = $c->model('DB::StorageSlot')->search({ member_id => undef })->count();
	my $occupied_slots  = $c->model('DB::StorageSlot')->search({ member_id => { '!=' => undef } })->count();

	$out->{free_slots}     = $available_slots;
	$out->{occupied_slots} = $occupied_slots;
	$out->{requests}       = $request_count;
	$out->{response}       = \1;
	}

sub requests :Local :Args(0)
	{
	my ($self, $c)  = @_;
	my $out         = $c->stash()->{out};
	my $requests_rs = $c->model('DB::StorageRequest')->search({ status => { not_in => ['accepted', 'rejected'] } });
	my @requests;

	while (my $request = $requests_rs->next())
		{
		push(@requests, $request->TO_FULL_JSON());
		}

	$out->{requests} = \@requests;
	$out->{response} = \1;
	}

sub decide_request :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};
	my $in         = $c->stash()->{in};
	my $action     = lc($in->{action} || '');
	my $request    = $c->model('DB::StorageRequest')->find($in->{request_id});
	my $slot;

	$out->{response} = \0;
	if (!$request)
		{
		$out->{data} = "Could not find request \"$in->{request_id}\".";
		return;
		}
	if ($action ne 'accept' && $action ne 'reject')
		{
		$out->{data} = "Invalid action \"$action\".";
		return;
		}
	if ($action eq 'accept')
		{
		$slot = $c->model('DB::StorageSlot')->find($in->{slot_id});
		if (!$slot)
			{
			$out->{data} = "Could not find slot \"$in->{slot_id}\".";
			return;
			}
		$out->{response} = \1;
		try
			{
			$c->model('DB')->txn_do(sub
				{
				$request->update(
					{
					status             => 'accepted',
					deciding_member_id => $c->user()->member_id(),
					decision_notes     => $in->{notes},
					decided_at         => \'NOW()',
					slot_id            => $slot->slot_id(),
					}) || die $!;
				$slot->assign($request->member_id(), $c);
				});
			}
		catch
			{
			$out->{response} = \0;
			$out->{data}     = 'Could not fulfil request.';
			};
		}
	else
		{
		$request->update(
			{
			status             => 'rejected',
			deciding_member_id => $c->user()->member_id(),
			decision_notes     => $in->{notes},
			decided_at         => \'NOW()',
			}) || die $!;
		$out->{response} = \1;
		}
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
	my $data        = {};
	my $slot;

	$out->{response} = \0;
	$out->{data}     = $slot_id ? 'Could not edit slot.' : 'Could not add slot.';

	if (!$location_id && !$slot_id)
		{
		$out->{data} = 'You must provide either a slot or a location.';
		return;
		}
	if (!$slot_id && !$name)
		{
		$out->{data} = 'You must provide a name for a new slot.';
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

	$data->{name}        = $name
		if ($name);
	$data->{sort_order}  = int($in->{sort_order})
		if (exists($in->{sort_order}) && defined($in->{sort_order}));
	$data->{location_id} = $location_id
		if ($location_id);

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
			$slot->assign($member_id, $c);
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
