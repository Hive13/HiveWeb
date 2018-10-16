use utf8;
package HiveWeb::Schema::Result::LampPreset;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw[ UUIDColumns InflateColumn::DateTime ]);
__PACKAGE__->table('lamp_preset');

__PACKAGE__->add_columns(
  'preset_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('preset_id');
__PACKAGE__->uuid_columns(qw[ preset_id ]);

__PACKAGE__->has_many(
  'bulb_presets',
  'HiveWeb::Schema::Result::LampBulbPreset',
  { 'foreign.preset_id' => 'self.preset_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		preset_id => $self->preset_id(),
		name      => $self->name(),
		};
	}
1;
