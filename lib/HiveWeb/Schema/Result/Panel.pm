use utf8;
package HiveWeb::Schema::Result::Panel;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('panel');

__PACKAGE__->add_columns(
  'panel_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'title',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'style',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'permissions',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'large',
  { data_type => 'boolean', is_nullable => 0, default_value => 'f' },
  'visible',
  { data_type => 'boolean', is_nullable => 0, default_value => 't' },
  'sort_order',
  { data_type => 'integer', is_nullable => 0, default_value => 1000 },
);

__PACKAGE__->set_primary_key('panel_id');
__PACKAGE__->uuid_columns('panel_id');
__PACKAGE__->resultset_attributes( { order_by => ['sort_order', 'name'] } );

__PACKAGE__->has_many(
  'member_panels',
  'HiveWeb::Schema::Result::MemberPanel',
  { 'foreign.panel_id' => 'self.panel_id' },
  { is_deferrable => 0, cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		panel_id    => $self->panel_id(),
		name        => $self->name(),
		title       => $self->title(),
		style       => $self->style(),
		permissions => $self->permissions(),
		large       => $self->large() ? \1 : \0,
		visible     => $self->visible() ? \1 : \0,
		sort_order  => $self->sort_order(),
		};
	}

1;
