package HiveWeb::Controller::API::Temperature;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('current');
	}

sub current :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{in}->{period} = 'current';
	$c->detach('retrieve');
	}

sub retrieve :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in     = $c->stash()->{in};
	my $out    = $c->stash()->{out};
	my $wanted = $in->{temp};
	my $period = lc($in->{period});

	$period = 'current'
		if ($period ne 'current' && $period ne 'day');

	if ($wanted)
		{
		$wanted = [ $wanted ]
			if (ref($wanted) ne 'ARRAY');
		$wanted = map { $_ => 1 } @$wanted;
		}

	my $items = $c->model('DB::Item')->search({}, { order_by => 'me.display_name' });
	my $temps = [];
	while (my $item = $items->next())
		{
		next
			if ($wanted && !$wanted->{ $item->name() });
		if ($period eq 'current')
			{
			my $temp = $item->search_related('temp_logs', {},
				{
				order_by => { -desc => 'create_time' },
				rows     => 1,
				})->first();
			push (@$temps,
				{
				name         => $item->display_name(),
				display_name => $item->display_name(),
				temperature  => $temp,
				})
				if ($temp);
			}
		elsif ($period eq 'day')
			{
			my @item_temps = $item->search_related('temp_logs', { create_time => \"now() - interval '1 day'" }, { order_by => { -desc => 'create_time' } })->all();
			push (@$temps,
				{
				name         => $item->display_name(),
				display_name => $item->display_name(),
				temperatures => @item_temps,
				})
				if (@item_temps);
			}
		}

	if ($temps)
		{
		$out->{temps}    = $temps;
		$out->{response} = \1;
		}
	else
		{
		$out->{response} = \0;
		}
	}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
