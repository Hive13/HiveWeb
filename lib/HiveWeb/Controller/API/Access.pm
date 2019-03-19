package HiveWeb::Controller::API::Access;
use Moose;
use namespace::autoclean;

use Bytes::Random::Secure qw(random_bytes);
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path
	{
	my ($self, $c) = @_;
	my $stash      = $c->stash();
	my $in         = $stash->{in};
	my $out        = $stash->{out};
	my $device     = $c->model('DB::Device')->find({ name => $in->{device} });
	my $data       = $in->{data};
	my $version    = int($data->{version} || 1);
	my $view       = $c->view('ChecksummedJSON');
	my $operation  = lc($data->{operation} // 'access');

	if (!defined($device))
		{
		$out->{data} = 'Cannot find device.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}

	$stash->{view}   = $view;
	$stash->{device} = $device;

	if ($device->min_version() > $version || $version > $device->max_version())
		{
		$out->{data} = 'Invalid version for device.';
		$c->response()->status(403)
			if ($data->{http});
		return;
		}

	if ($version >= 2)
		{
		my $nonce     = $data->{nonce} // '';
		my $exp_nonce = uc(unpack('H*', $device->nonce()));
		my $new_nonce = random_bytes(16);
		$device->update({ nonce => $new_nonce });
		$out->{new_nonce} = uc(unpack('H*', $new_nonce));
		if ($nonce ne $exp_nonce && $operation ne 'get_nonce')
			{
			$out->{nonce_valid} = \0;
			$out->{data}        = 'Invalid nonce.';
			$c->response()->status(403)
				if ($data->{http});
			return;
			}
		$out->{nonce_valid} = \1;
		}

	my $shasum = $view->make_hash($c, $data);
	if ($shasum ne uc($in->{checksum}))
		{
		$out->{data} = 'Invalid checksum.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}

	$out->{random_response} = $data->{random_response};

	$c->detach($operation)
		if ($self->can($operation));

	$out->{response} = \0;
	$out->{error} = 'Invalid operation.';
	$c->response()->status(400)
		if ($data->{http});
	}

sub access :Private
	{
	my ($self, $c) = @_;
	my $stash      = $c->stash();
	my $data       = $stash->{in}->{data};
	my $out        = $stash->{out};
	my $device     = $stash->{device};
	my $item_name  = $data->{location} // $data->{item};
	my $item       = $c->model('DB::Item')->find({ name => $item_name });
	my $badge      = $c->model('DB::Badge')->find( { badge_number => $data->{badge} } );
	my $member     = $badge ? $badge->member() : undef;
	my $access     = 0;
	$out->{access} = \$access;

	if (!$item)
		{
		$out->{error} = 'Cannot find item ' . $item_name;
		$c->response()->status(401)
			if ($data->{http});
		return;
		}
	$out->{response} = \1;

	if ($device->search_related('device_items', { item_id => $item->item_id() })->count() < 1)
		{
		$out->{error} = "Device not authorized for " . $item;
		$c->response()->status(401)
			if ($data->{http});
		return;
		}

	$access = $member->has_access($item) ? 1 : 0
		if ($member);

	$item->create_related('access_logs',
		{
		granted   => $access,
		member_id => $member ? $member->member_id() : undef,
		badge_id  => $badge->badge_number(),
		}) || die $!;

	if (!$member)
		{
		$out->{error} = 'Unknown badge ' . $badge;
		$c->response()->status(401)
			if ($data->{http});
		return;
		}

	if (!$access)
		{
		$out->{error} = 'Access denied';
		$c->response()->status(401)
			if ($data->{http});
		return;
		}
	}

sub vend :Private
	{
	my ($self, $c)   = @_;
	my $stash        = $c->stash();
	my $out          = $stash->{out};
	my $device       = $stash->{device};
	my $data         = $stash->{in}->{data};
	my $badge        = $c->model('DB::Badge')->find({ badge_number => $data->{badge} });
	my $member       = $badge ? $badge->member() : undef;
	my $vend         = 0;
	$out->{error}    = 'Cannot find member associated with this badge.';
	$out->{vend}     = \$vend;
	$out->{response} = \1;

	if ($member)
		{
		$vend         = $member->do_vend() ? 1 : 0;
		$out->{error} = $vend ? 'Have a soda!' : 'You have no soda credits.';
		}

	$device->create_related('vend_logs',
		{
		member_id => $member ? $member->member_id() : undef,
		vended    => $vend,
		badge_id  => $data->{badge},
		});
	}

sub get_light_state
	{
	my ($self, $c) = @_;
	my $stash      = $c->stash();
	my $out        = $stash->{out};
	my $device     = $stash->{device};
	my $data       = $stash->{in}->{data};

	my @presets = $device
		->search_related('bulbs', { 'preset.name' => 'current' }, { join => { bulb_presets => 'preset' } })
		->get_column('bulb_presets.value')->all();

	$out->{states}   = \@presets;
	$out->{response} = \1;
	}

sub log :Private
	{
	my ($self, $c) = @_;
	my $stash      = $c->stash();
	my $out        = $stash->{out};
	my $device     = $stash->{device};
	my $data       = $stash->{in}->{data};
	my $iname      = $data->{log_data}->{item} // '';
	my $item       = $c->model('DB::Item')->find( { name => $iname } );

	if (!$item)
		{
		$out->{error} = "Unknown item " . $iname;
		$c->response()->status(401)
			if ($data->{http});
		return;
		}

	my $d_i = $device
		->search_related('device_items', { item_id => $item->item_id() });

	if ($d_i->count() < 1)
		{
		$out->{error} = "Device not authorized for " . $iname;
		$c->response()->status(401)
			if ($data->{http});
		return;
		}

	my $temp_log = $item->create_related('temp_logs',
		{
		temperature => $data->{log_data}->{temperature},
		});
	if ($temp_log)
		{
		$out->{response}    = \1;
		$out->{error}       = 'Data logged.';
		$out->{temp_log_id} = $temp_log->temp_log_id();
		}
	else
		{
		$out->{error} = 'Could not log temperature.';
		}
	}

sub soda_status :Private
	{
	my ($self, $c)   = @_;
	my $stash        = $c->stash();
	my $out          = $stash->{out};
	my $device       = $stash->{device};
	my $data         = $stash->{in}->{data};
	my $sodas        = $data->{soda_status};
	$out->{response} = \1;
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $soda (@$sodas)
				{
				my $slot = $c->model('DB::SodaStatus')->find({ slot_number => $soda->{slot} }) || die;
				$slot->update({ sold_out => ($soda->{sold_out} ? 't' : 'f') });
				}
			});
		}
	catch
		{
		$out->{response} = \0;
		};
	}

sub get_nonce :Private
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
