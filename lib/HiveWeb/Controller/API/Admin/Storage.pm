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

	my $root_location = $c->model('DB::StorageLocation')->find({ parent_id => undef }) || die $!;
	my $request_count = $c->model('DB::StorageRequest')->search({ status => 'requested' })->count();

	$out->{locations} = $root_location->TO_FULL_JSON();
	$out->{requests}  = $request_count;
	$out->{response}  = \1;
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};

	my $request_count   = $c->model('DB::StorageRequest')->search({ status => 'requested' })->count();
	my $available_slots = $c->model('DB::StorageSlot')->search({ member_id => undef })->count();
	my $occupied_slots  = $c->model('DB::StorageSlot')->search({ member_id => { '!=' => undef } })->count();

	my @types;
	my $type_rs = $c->model('DB::StorageSlotType');
	while (my $type = $type_rs->next())
		{
		my $type_id = $type->type_id();
		my $request_count   = $c->model('DB::StorageRequest')->search({ status => 'requested', type_id => $type_id })->count();
		my $available_slots = $c->model('DB::StorageSlot')->search({ member_id => undef, type_id => $type_id })->count();
		my $occupied_slots  = $c->model('DB::StorageSlot')->search({ member_id => { '!=' => undef }, type_id => $type_id })->count();
		push(@types,
			{
			name           => $type->name(),
			type_id        => $type_id,
			can_request    => $type->can_request() ? \1 : \0,
			requests       => $request_count,
			free_slots     => $available_slots,
			occupied_slots => $occupied_slots,
			});
		}

	$out->{free_slots}     = $available_slots;
	$out->{occupied_slots} = $occupied_slots;
	$out->{requests}       = $request_count;
	$out->{types}          = \@types;
	$out->{response}       = \1;
	}

sub requests :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};
	my $in         = $c->stash()->{in};
	my $search     = { status => 'requested' };

	if ($in->{type_id})
		{
		$search->{type_id} = $in->{type_id};
		}

	my $requests_rs = $c->model('DB::StorageRequest')->search($search);
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

	my $updates =
		{
		deciding_member_id => $c->user()->member_id(),
		decision_notes     => $in->{notes},
		decided_at         => \'NOW()',
		};

	if (!$request)
		{
		$out->{data} = "Could not find request \"$in->{request_id}\".";
		return;
		}
	try
		{
		$out->{response} = \1;
		$c->model('DB')->txn_do(sub
			{
			if ($action eq 'reject')
				{
				$updates->{status} = 'rejected';
				}
			elsif ($action eq 'accept')
				{
				if ($request->slot_id())
					{
					$updates->{status} = 'renewed';
					$slot = $request->slot();
					$request->member()->remove_group(\$c->config()->{storage}->{remind_group}, 'Renewed slot ' . $slot->name());
					}
				else
					{
					$slot = $c->model('DB::StorageSlot')->find($in->{slot_id});
					if (!$slot)
						{
						$out->{data} = "Could not find slot \"$in->{slot_id}\".";
						return;
						}
					$updates->{slot_id} = $slot->slot_id();
					$updates->{status}  = 'accepted';
					}
				$slot->assign($request->member_id());
				}
			else
				{
				$out->{data} = 'Invalid action type.';
				return;
				}
			$request->update($updates) || die $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not fulfil request.';
		};
	}

sub edit_location :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $location;
	my $in   = $c->stash()->{in};
	my $out  = $c->stash()->{out};
	my $data =
		{
		name        => $in->{name},
		parent_id   => $in->{parent_id},
		sort_order  => $in->{sort_order},
		location_id => $in->{location_id},
		};

	if ($data->{location_id} && !($location = $c->model('DB::StorageLocation')->find($data->{location_id})))
		{
		$out->{data} = 'Could not find location.';
		return;
		}
	if (!$data->{location_id} && (!$data->{parent_id} || !$data->{name}))
		{
		$out->{data} = 'You must provide a name and a parent for a new location.';
		return;
		}
	if ($data->{parent_id} && !$c->model('DB::StorageLocation')->find({ location_id => $data->{parent_id} }))
		{
		$out->{data} = 'Invalid parent specified.';
		return;
		}

	$out->{data} = $data->{location_id} ? 'Could not edit location.' : 'Could not add location.';
	if ($data->{location_id})
		{
		$location->update($data) || die $!;
		$out->{data} = 'Location updated.';
		}
	else
		{
		$location    = $c->model('DB::StorageLocation')->create($data) || die $!;
		$out->{data} = 'Location added.';
		}

	$out->{response}    = \1;
	$out->{location_id} = $location->location_id();
	}

sub delete_location :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in          = $c->stash()->{in};
	my $out         = $c->stash()->{out};
	my $location_id = $in->{location_id};
	my $location;

	$out->{data} = 'Could not delete location.';

	if (!$location_id || !($location = $c->model('DB::StorageLocation')->find($location_id)))
		{
		$out->{data} = 'Invalid slot specified.';
		return;
		}

	if ($location->children()->count() || $location->slots()->count())
		{
		$out->{data} = 'This location still has children.';
		return;
		}

	$location->delete() || die $!;
	$out->{data} = 'Location deleted.';
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
