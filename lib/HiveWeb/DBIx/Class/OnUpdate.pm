package HiveWeb::DBIx::Class::OnUpdate;

use strict;
use warnings;

use base 'DBIx::Class::Row';

sub update
	{
	my ($self, $data, @rest) = @_;

	my $source = $self->result_source();
	my $info   = $source->columns_info();
	my $schema = $source->schema();
	my $guard  = $schema->txn_scope_guard();
	my $old_row;
	my $res;
	my %did;

	$data //= {};

	foreach my $col (keys %$info)
		{
		my $routine = $info->{$col}{on_update};
		if ($routine && $self->can($routine))
			{
			my $new = exists($data->{$col}) ? $data->{$col} : $self->get_column($col);
			$old_row //= $source->resultset()->find($self->id());
			my $old = $old_row->get_column($col);
			if ((defined($old) ne defined($new) || (defined($old) && defined($new) && $old ne $new)) && !exists($did{\$routine}))
				{
				$self->$routine($old_row, $self);
				$did{\$routine} = 1;
				}
			}
		}

	$res = $self->next::method($data, @rest) || die $!;
	$guard->commit();
	return $res;
	}

1;
