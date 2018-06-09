package HiveWeb::Schema::ResultSet::AccessLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# There's gotta be a better way
sub heatmap
	{
	my $self = shift;

	return $self->search(
		{
		},
		{
		'select' =>
			[
			\ q{COUNT(DISTINCT CONCAT(member_id, '-', EXTRACT(year FROM access_time), '-', EXTRACT(month FROM access_time), '-', EXTRACT(day FROM access_time), '-', EXTRACT(hour FROM access_time), '-', (EXTRACT(minute FROM access_time)::integer / 15)))},
			\'EXTRACT(dow FROM me.access_time)',
			\'EXTRACT(hour FROM me.access_time)',
			\'(EXTRACT(minute FROM me.access_time)::integer / 15)',
			],
		'as' => ['count', 'dow', 'hour', 'qhour'],
		group_by => \'2, 3, 4',
		order_by => \'2, 3, 4',
		}
	);
	}

1;
