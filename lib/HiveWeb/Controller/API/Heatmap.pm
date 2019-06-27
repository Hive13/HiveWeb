package HiveWeb::Controller::API::Heatmap;
use Moose;
use namespace::autoclean;

use Math::Round;
use DateTime::Format::ISO8601;

BEGIN { extends 'Catalyst::Controller' }

sub log10 :Private
	{
	my $n = shift;

	return log($n);
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('accesses');
	}

sub accesses :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	$out->{response} = \0;

	my $dow   = [];
	my $max   = 0;
	my $scale = sub { return shift; };
	my $iname = $in->{item} // 'main_door';
	my $item  = $c->model('DB::Item')->find({ name => $iname });

	if (!$item)
		{
		$out->{data} = 'Invalid item name.';
		return;
		}

	my $search =
		{
		granted => 't',
		item_id => $item->item_id(),
		};

	$scale = \&log10
		if (lc($in->{scale}) eq 'log');

	my $heatmap = $c->model('DB::AccessLog')->heatmap()->search($search);
	if (exists($in->{range}))
		{
		my $range = lc($in->{range});
		if ($range eq 'year')
			{
			$search->{access_time} = { '>=' => \'now() - interval \'1 year\'' };
			}
		elsif ($range eq 'half_year')
			{
			$search->{access_time} = { '>=' => \'now() - interval \'6 months\'' };
			}
		elsif ($range eq 'quarter')
			{
			$search->{access_time} = { '>=' => \'now() - interval \'3 months\'' };
			}
		elsif ($range eq 'month')
			{
			$search->{access_time} = { '>=' => \'now() - interval \'1 month\'' };
			}
		elsif ($range eq 'custom')
			{
			if (!exists($in->{start_date}) || !exists($in->{end_date}))
				{
				$out->{data} = 'You must provide start and end dates.';
				return;
				}
			my $start  = DateTime::Format::ISO8601->parse_datetime($in->{start_date}) || die $!;
			my $end    = DateTime::Format::ISO8601->parse_datetime($in->{end_date}) || die $!;
			$end->add(days => 1);
			$search->{access_time} =
				{
				'>=' => $start->ymd('-'),
				'<'  => $end->ymd('-'),
				};
			}
		elsif ($range ne 'all')
			{
			$out->{data} = 'Invalid range specified.';
			return;
			}
		}

	while (my $entry = $heatmap->next())
		{
		my $column = $entry->get_column('hour') * 4 + $entry->get_column('qhour');
		my $value  = $entry->get_column('count');
		my $cdow   = $entry->get_column('dow');
		$max = $value
			if ($max < $value);
		$dow->[$cdow] //= [];
		$dow->[$cdow]->[$column] = $value;
		}

	$max = $scale->($max) || 1;

	for (my $i = 0; $i < 7; $i++)
		{
		$dow->[$i] //= [];
		for (my $j = 0; $j < (24 * 4); $j++)
			{
			my $v = int($dow->[$i]->[$j] || 0);
			$v = ($scale->($v) * 100) / $max;
			$dow->[$i]->[$j] = round($v);
			}
		}

	$out->{accesses} = $dow;
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
