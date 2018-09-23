package HiveWeb::Controller::API::Lights;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub auto :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{out}->{response} = \0;
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
	my $bulb_rs = $current->search_related('bulb_presets', {},
		{
		prefetch => { 'bulb' => 'color' },
		order_by => [ 'bulb.lamp_id', 'bulb.slot' ],
		});
	my @lamps;
	my $oid;
	my $lamp;
	my $bulbs;

	while (my $bulb_ps = $bulb_rs->next())
		{
		my $bulb = $bulb_ps->bulb();
		my $lamp = $bulb->lamp();
		my $id   = $bulb->lamp_id();

		if ($oid != $id)
			{
			$bulbs = [];
			push(@lamps,
				{
				bulbs   => $bulbs,
				lamp_id => $id,
				name    => $lamp->name(),
				});
			$oid = $id;
			}
		push (@$bulbs,
			{
			bulb_id => $bulb->bulb_id(),
			slot    => $bulb->slot(),
			state   => $bulb_ps->value(),
			});
		}

	$out->{lamps}    = \@lamps;
	$out->{configs}  = $configs;
	$out->{response} = \1;
	}

sub off :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $bulb_rs = $current->bulb_presets() || return;

	$bulb_rs->update({ value => 0 });

	$out->{response} = \1;
	}

sub on :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $current = $c->model('DB::LampPreset')->find({ name => 'current' }) || return;
	my $bulb_rs = $current->bulb_presets() || return;

	$bulb_rs->update({ value => 1 });

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

	$bulb_rs->update({ value => 1 });

	$out->{response} = \1;
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
