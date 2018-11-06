package HiveWeb::DBIx::Class::Core;

use strict;
use warnings;

use base 'DBIx::Class::Core';

sub inflate_result
	{
	my $self = shift;
	my $ret  = $self->next::method(@_);

	if ($self->can('admin_class') && $HiveWeb::Schema::is_admin)
		{
		my $class = $self->admin_class();
		$self->ensure_class_loaded($class);
		bless $ret, $class;
		}

	return $ret;
	}

1;
