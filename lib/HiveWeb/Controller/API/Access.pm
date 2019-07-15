package HiveWeb::Controller::API::Access;
use Moose;
use namespace::autoclean;

use Bytes::Random::Secure qw(random_bytes);
use Try::Tiny;
use DateTime;

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
		$out->{error} = "Device not authorized for $item";
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
		badge_id  => $data->{badge},
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

	return if (!$member);

	my $credits = $member->vend_credits() || 0;
	my $count   = $member->vend_total() || 0;
	$c->model('DB')->txn_do(sub
		{
		if ($credits < 1)
			{
			$out->{error} = 'You have no soda credits.';
			}
		else
			{
			my $alert_credits = $member->alert_credits();
			$count++;
			$credits--;
			$member->update(
				{
				vend_total   => $count,
				vend_credits => $credits,
				});
			if (defined($alert_credits) && $credits <= $alert_credits)
				{
				$out->{alert} = \1
					if ($member->alert_machine());

				if ($member->alert_email())
					{
					$c->model('DB::Action')->create(
						{
						action_type       => 'member.alert_credit',
						queuing_member_id => $member->member_id(),
						row_id            => $member->member_id(),
						}) || die 'Could not queue notification: ' . $!;
					}
				}
			$vend = 1;
			$out->{error} = 'Have a soda.';
			}

		$member->create_related('vend_logs',
			{
			device_id => $device->device_id(),
			vended    => $vend,
			badge_id  => $data->{badge},
			});
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
		$out->{error} = "Unknown item $iname";
		$c->response()->status(401)
			if ($data->{http});
		return;
		}

	my $d_i = $device
		->search_related('device_items', { item_id => $item->item_id() });

	if ($d_i->count() < 1)
		{
		$out->{error} = "Device not authorized for $iname";
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

sub quiet_hours :Local
	{
	my ($self, $c)  = @_;
	my $quiet_hours = $c->config()->{quiet_hours};
	my $out         = $c->stash()->{out};
	my $now         = DateTime->now( time_zone => 'local' );

	foreach my $event ('start', 'end')
		{
		my $e = $now->clone()->set($quiet_hours->{$event});
		my $time;
		do
			{
			my $when = $e->subtract_datetime($now);
			my @time = $when->in_units('minutes', 'seconds', 'nanoseconds');
			$time = ($time[0] * 60 + $time[1]) * 1000 + int($time[2] / 1_000_000);
			$e->add( days => 1 );
			} while ($time < 0);
		$out->{"${event}_ms"} = $time;
		}
	$out->{in_quiet} = $out->{start_ms} > $out->{end_ms} ? \1 : \0;
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
