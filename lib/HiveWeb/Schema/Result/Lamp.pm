use utf8;
package HiveWeb::Schema::Result::Lamp;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'HiveWeb::DBIx::Class::Core';

__PACKAGE__->load_components(qw[ UUIDColumns InflateColumn::DateTime ]);
__PACKAGE__->table('lamp');

__PACKAGE__->add_columns(
  'lamp_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0 },
  'ip_address',
  { data_type => 'inet', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('lamp_id');
__PACKAGE__->uuid_columns(qw[ lamp_id ]);

__PACKAGE__->has_many(
  'bulbs',
  'HiveWeb::Schema::Result::LampBulb',
  { 'foreign.lamp_id' => 'self.lamp_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many('bulb_presets', 'bulbs', 'bulb_presets');

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		lamp_id => $self->lamp_id(),
		name    => $self->name(),
		};
	}

sub admin_class
	{
	return __PACKAGE__ . '::Admin';
	}

1;

package HiveWeb::Schema::Result::MemberCurse::Admin;

use strict;
use warnings;
use base qw/HiveWeb::Schema::Result::MemberCurse/;

__PACKAGE__->table('lamp');

sub TO_JSON
	{
	my $self = shift;

	return
		{
		lamp_id    => $self->lamp_id(),
		name       => $self->name(),
		ip_address => $self->ip_address(),
		};
	}

1;
