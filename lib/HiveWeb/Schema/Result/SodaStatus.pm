use utf8;
package HiveWeb::Schema::Result::SodaStatus;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ InflateColumn::Object::Enum UUIDColumns });
__PACKAGE__->table('soda_status');

__PACKAGE__->add_columns(
	'soda_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'name',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'sold_out',
	{ data_type => 'boolean', is_nullable => 0, default_value => 'f' },
	'slot_number',
	{ data_type => 'integer', is_nullable => 0 },
	'type' =>
		{
		data_type => 'enum',
		is_enum => 1,
		extra => { list => ['regular', 'diet', 'water', 'beer'] },
		},
);

__PACKAGE__->set_primary_key('soda_id');
__PACKAGE__->uuid_columns('soda_id');
__PACKAGE__->resultset_attributes( { order_by => ['slot_number'] } );

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		soda_id     => $self->soda_id(),
		name        => $self->name(),
		type        => $self->type(),
		sold_out    => $self->sold_out() ? \1 : \0,
		slot_number => $self->slot_number(),
		};
	}

1;
