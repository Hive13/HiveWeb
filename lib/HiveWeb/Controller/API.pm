package HiveWeb::Controller::API;
use Moose;
use namespace::autoclean;

use JSON;
use Bytes::Random::Secure qw(random_bytes);
use MIME::Base64;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub find_member :Private
	{
	my $c        = shift;
	my $badge_no = shift;
	my $badge    = $c->model('DB::Badge')->find( { badge_number => $badge_no } );

	return $badge->member()
		if (defined($badge));
	}

sub has_access :Private
	{
	my $c        = shift;
	my $badge_no = shift;
	my $iname    = shift;
	my $item     = $c->model('DB::Item')->find( { name => $iname } );
	my $member   = find_member($c, $badge_no);
	my $access   = 0;
	my $member_id;

	return "Invalid item"
		if (!defined($item));

	if ($member)
		{
		$member_id = $member->member_id();
		$access    = $member->has_access($item);
		}

	my $access_log = $c->model('DB::AccessLog')->create(
		{
		item_id   => $item->item_id(),
		granted   => $access ? 1 : 0,
		member_id => $member_id,
		badge_id  => $badge_no,
		});

	return "Invalid badge"
		if (!defined($member));
	return $access ? undef : "Access denied";
	}

sub begin :Private
	{
	my ($self, $c) = @_;

	if (lc($c->req()->content_type()) eq 'multipart/form-data')
		{
		$c->stash()->{in} = $c->req()->body_parameters();
		}
	else
		{
		$c->stash()->{in} = $c->req()->body_data();
		}
	$c->stash()->{out} = { response => \0 };
	$c->stash()->{view} = $c->view('JSON');
	}

sub end :Private
	{
	my ($self, $c) = @_;

	$c->detach($c->stash()->{view});
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->response->body('Matched HiveWeb::Controller::API in API.');
	}

sub access :Local
	{
	my ($self, $c) = @_;
	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $device    = $c->model('DB::Device')->find({ name => $in->{device} });
	my $data      = $in->{data};
	my $version   = int($data->{version} || 1);
	my $view      = $c->view('ChecksummedJSON');
	my $operation = lc($data->{operation} // 'access');

	if (!defined($device))
		{
		$out->{error}    = 'Cannot find device.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}

	$c->stash()->{view}   = $view;
	$c->stash()->{device} = $device;

	if ($device->min_version() > $version || $version > $device->max_version())
		{
		$out->{error}    = 'Invalid version for device.';
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
			$out->{error}       = 'Invalid nonce.';
			$c->response()->status(403)
				if ($data->{http});
			return;
			}
		$out->{nonce_valid} = \1;
		}

	my $shasum = $view->make_hash($c, $data);
	if ($shasum ne uc($in->{checksum}))
		{
		$out->{error} = 'Invalid checksum.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}

	$out->{response}        = \1;
	$out->{random_response} = $data->{random_response};

	if ($operation eq 'access')
		{
		my $badge  = $data->{badge};
		my $item   = $data->{location} // $data->{item};
		my $access = has_access($c, $badge, $item);
		my $d_i    = $device
			->search_related('device_items')
			->search_related('item', { name => $item } );

		if ($d_i->count() < 1)
			{
			$out->{access} = \0;
			$out->{error}  = "Device not authorized for " . $item;
			$c->response()->status(401)
				if ($data->{http});
			return;
			}
		if (defined($access))
			{
			$out->{access} = \0;
			$out->{error}  = $access;
			$c->response()->status(401)
				if ($data->{http});
			return;
			}
		$out->{access} = \1;
		}
	elsif ($operation eq 'vend')
		{
		my $member = find_member($c, $data->{badge});
		my $vend   = 0;
		my $member_id;

		$out->{error} = 'Cannot find member associated with this badge.';
		if ($member)
			{
			$member_id    = $member->member_id();
			$out->{error} = 'Have a soda!';

			$vend = $member->do_vend();
			$out->{error} = 'You have no soda credits.'
				if (!$vend);
			}

		$device->create_related('vend_logs',
			{
			member_id => $member_id,
			vended    => $vend ? 1 : 0,
			badge_id  => $data->{badge},
			});

		$out->{vend} = $vend ? \1 : \0;
		}
	elsif ($operation eq 'log')
		{
		my $iname = $data->{log_data}->{item} // '';
		my $item  = $c->model('DB::Item')->find( { name => $iname } );
		if (!$item)
			{
			$out->{response} = \0;
			$out->{error}    = "Unknown item " . $iname;
			$c->response()->status(401)
				if ($data->{http});
			return;
			}

		my $d_i = $device
			->search_related('device_items', { item_id => $item->item_id() });

		if ($d_i->count() < 1)
			{
			$out->{response} = \0;
			$out->{error}    = "Device not authorized for " . $iname;
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
			$out->{response} = \0;
			$out->{error}    = 'Could not log temperature.';
			}
		}
	elsif ($operation eq 'soda_status')
		{
		my $sodas = $data->{soda_status};
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
	elsif ($operation eq 'get_light_state')
		{
		my @presets = $device
			->search_related('bulbs', { 'preset.name' => 'current' }, { join => { bulb_presets => 'preset' } })
			->get_column('bulb_presets.value')->all();

		$out->{states}   = \@presets;
		$out->{response} = \1;
		}
	elsif ($operation eq 'get_nonce')
		{
		$out->{response} = \1;
		}
	else
		{
		$out->{response} = JSON->false();
		$out->{error} = 'Invalid operation.';
		$c->response()->status(400)
			if ($data->{http});
		}
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
  $out->{sodas}  = [ $c->model('DB::SodaStatus')->search({},
		{
		prefetch => 'soda_type'
		}) ];

	my $wanted = $in->{temp};

	if ($wanted)
		{
		$wanted = [ $wanted ]
			if (ref($wanted) ne 'ARRAY');
		$wanted = map { $_ => 1 } @$wanted;
		}

	my $items = $c->model('DB::Item')->search({}, { order_by => 'me.display_name' });
	$out->{temps} = [];
	while (my $item = $items->next())
		{
		next
			if ($wanted && !$wanted->{ $item->name() });
		my $temp = $item->search_related('temp_logs', {},
			{
			order_by => { -desc => 'create_time' },
			rows     => 1,
			prefetch => 'item',
			})->first();

		push (@{ $out->{temps} }, $temp)
			if ($temp);
		}
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
