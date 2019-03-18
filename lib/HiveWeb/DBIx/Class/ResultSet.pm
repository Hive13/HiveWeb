package HiveWeb::DBIx::Class::ResultSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub hashref
	{
	my $self = shift;

	return $self->search({}, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
	}

1;
