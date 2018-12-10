package HiveWeb::Controller::API::Lights;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use IO::Socket::INET;

BEGIN { extends 'Catalyst::Controller' }

sub send_updates
	{
	my ($self, $c) = shift;

	my $sock = new IO::Socket::INET(
		PeerAddr => '239.72.49.51',
		PeerPort => 12595,
		Proto    => 'udp',
		Timeout  => 1
	) or die('Error opening socket.');

	my $data = "light";
	print $sock $data;
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('status');
	}

sub status :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $configs = [ $c->model('DB::LampPreset')->all() ];
	my $colors  = [ $c->model('DB::LampColor')->all() ];
	my $bulb_rs = $current->search_related('bulb_presets', {},
		{
		prefetch => { 'bulb' => 'color' },
		order_by => [ 'bulb.device_id', 'bulb.slot' ],
		});
	my @devices;
	my $oid;
	my $bulbs;

	while (my $bulb_ps = $bulb_rs->next())
		{
		my $bulb   = $bulb_ps->bulb();
		my $device = $bulb->device();
		my $id     = $bulb->device_id();

		if ($oid != $id)
			{
			$bulbs = [];
			push(@devices,
				{
				bulbs     => $bulbs,
				device_id => $id,
				name      => $device->name(),
				});
			$oid = $id;
			}
		push (@$bulbs,
			{
			bulb_id  => $bulb->bulb_id(),
			slot     => $bulb->slot(),
			state    => $bulb_ps->value(),
			color_id => $bulb->color_id(),
			});
		}

	$out->{devices}  = \@devices;
	$out->{configs}  = $configs;
	$out->{colors}   = { map { $_->color_id() => $_ } @$colors };
	$out->{response} = \1;
	}

sub off :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $bulb_rs = $current->bulb_presets() || return;

	$bulb_rs->update({ value => 0 });

	$self->send_updates($c);

	$out->{response} = \1;
	}

sub on :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $bulb_rs = $current->bulb_presets() || return;

	$bulb_rs->update({ value => 1 });

	$self->send_updates($c);

	$out->{response} = \1;
	}

sub load :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out      = $c->stash()->{out};
	my $in       = $c->stash()->{in};
	my $selected = $c->model('DB::LampPreset')->find($in->{preset_id});
	my $current  = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;

	if (!$selected)
		{
		$out->{data} = 'Invalid preset.';
		return;
		}
	my $bulb_rs  = $selected->bulb_presets() || return;

	$c->model('DB')->txn_do(sub
		{
		while (my $bulb_ps = $bulb_rs->next())
			{
			$current
				->find_related('bulb_presets', { bulb_id => $bulb_ps->bulb_id() })
				->update({ value => $bulb_ps->value() });
			}
		});

	$self->send_updates($c);

	$out->{response} = \1;
	}

sub set :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out      = $c->stash()->{out};
	my $in       = $c->stash()->{in};
	my $current  = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $sets     = $in->{bulbs};

	$out->{response} = \1;
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $bulb_id (keys %$sets)
				{
				$current->update_or_create_related('bulb_presets',
					{
					bulb_id => $bulb_id,
					value   => ($sets->{$bulb_id} ? 't' : 'f'),
					}) || die $!;
				}
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     ='Cannot set current: ' . $_;
		};
	$self->send_updates($c);
	}

sub save :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $in      = $c->stash()->{in};
	my $save    = $c->model('DB::LampPreset')->find({ name => $in->{name} });
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;

	if (!$save)
		{
		$save = $c->model('DB::LampPreset')->create({ name => $in->{name} });
		}
	my $bulb_rs  = $current->bulb_presets() || return;

	$c->model('DB')->txn_do(sub
		{
		while (my $bulb_ps = $bulb_rs->next())
			{
			$save->find_or_create_related('bulb_presets',
				{
				bulb_id => $bulb_ps->bulb_id(),
				value   => $bulb_ps->value(),
				});
			}
		});

	$bulb_rs->update({ value => 1 });

	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
