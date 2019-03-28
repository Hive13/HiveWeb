package HiveWeb::DBIx::Class::OnUpdate;

use strict;
use warnings;

use base 'DBIx::Class::Row';

sub update
	{
	my ($self, $data, @rest) = @_;

	my $info = $self->result_source()->columns_info();
	my $old;

	$data //= {};

	foreach my $col (keys %$info)
		{
		my $routine = $info->{$col}{on_update};
		if ($routine && $self->can($routine))
			{
			my $new = exists($data->{$col}) ? $data->{$col} : $self->get_column($col);
			$old //= $self->result_source()->resultset()->find($self->id());
			if (defined($old) ne defined($new) || (defined($old) && defined($new) && $old ne $new))
				{
				$self->$routine($old->get_column($col), $new);
				}
			}
		}

	return $self->next::method($data, @rest);
	}

1;
