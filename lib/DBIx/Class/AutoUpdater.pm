package DBIx::Class::AutoUpdater;

use strict;
use warnings;

use base 'DBIx::Class::Row';

sub update
 	{
	my ($self, $data, @rest) = @_;

	my $info = $self->result_source->columns_info;

	$data //= {};

	foreach my $col (keys %$info)
		{
		if (exists($info->{$col}{auto_update}))
			{
			$data->{$col} = $info->{$col}{auto_update};
			}
		}

	return $self->next::method($data, @rest);
	}

1;
