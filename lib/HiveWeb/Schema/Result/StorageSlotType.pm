use utf8;
package HiveWeb::Schema::Result::StorageSlotType;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('storage_slot_type');

__PACKAGE__->add_columns(
	'type_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'name',
	{ data_type => 'character varying', is_nullable => 0 },
	'default_expire_time',
	{ data_type => 'character varying', is_nullable => 1 },
	'can_request',
	{ data_type => 'boolean', is_nullable => 0, default_value => 't' },
);

__PACKAGE__->set_primary_key('type_id');
__PACKAGE__->uuid_columns('type_id');

__PACKAGE__->has_many(
  'slots',
  'HiveWeb::Schema::Result::StorageSlot',
  { 'foreign.type_id' => 'self.type_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		type_id     => $self->type_id(),
		name        => $self->name(),
		can_request => $self->can_request() ? \1 : \0,
		};
	}

1;
