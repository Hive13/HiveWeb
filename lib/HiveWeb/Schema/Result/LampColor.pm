use utf8;
package HiveWeb::Schema::Result::LampColor;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw[ UUIDColumns InflateColumn::DateTime ]);
__PACKAGE__->table('lamp_color');

__PACKAGE__->add_columns(
  'color_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0 },
  'html_color',
  { data_type => 'character', size => 6, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('color_id');
__PACKAGE__->uuid_columns(qw[ color_id ]);

__PACKAGE__->has_many(
  'bulbs',
  'HiveWeb::Schema::Result::LampBulb',
  { 'foreign.bulb_id' => 'self.bulb_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		color_id   => $self->color_id(),
		name       => $self->name(),
		html_color => $self->html_color(),
		};
	}
1;
