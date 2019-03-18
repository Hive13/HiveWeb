package HiveWeb::Schema::ResultSet::Log;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub new_log
	{
	my ($self, $params) = @_;

	return $self->create($params);
	}

1;
