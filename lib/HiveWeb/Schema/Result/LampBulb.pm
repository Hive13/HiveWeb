use utf8;
package HiveWeb::Schema::Result::LampBulb;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw[ UUIDColumns InflateColumn::DateTime ]);
__PACKAGE__->table('lamp_bulb');

__PACKAGE__->add_columns(
  'bulb_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'device_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'color_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'slot',
  { data_type => 'integer', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('bulb_id');
__PACKAGE__->uuid_columns(qw[ bulb_id device_id color_id ]);
__PACKAGE__->resultset_attributes( { order_by => ['slot'] } );

__PACKAGE__->belongs_to(
  'device',
  'HiveWeb::Schema::Result::Device',
  { 'foreign.device_id' => 'self.device_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  'color',
  'HiveWeb::Schema::Result::LampColor',
  { 'foreign.color_id' => 'self.color_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	'bulb_presets',
	'HiveWeb::Schema::Result::LampBulbPreset',
	{ 'foreign.bulb_id' => 'self.bulb_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		bulb_id   => $self->bulb_id(),
		device_id => $self->device_id(),
		color_id  => $self->color_id(),
		slot      => $self->slot(),
		};
	}
1;
