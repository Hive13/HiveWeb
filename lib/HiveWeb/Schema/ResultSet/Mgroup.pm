use utf8;
package HiveWeb::Schema::ResultSet::Mgroup;

use strict;
use warnings;
use base 'HiveWeb::DBIx::Class::ResultSet';

sub find_group_id
	{
	my ($self, $group_id) = @_;

	my $ref = ref($group_id);
	if ($ref eq 'SCALAR')
		{
		my $group = $self->find({ name => $$group_id })
			|| die 'No such group';
		return $group->mgroup_id();
		}
	elsif ($ref)
		{
		return $group_id->mgroup_id();
		}
	
	return $group_id;
	}

1;
