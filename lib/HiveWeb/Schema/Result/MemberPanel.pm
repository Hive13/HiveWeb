use utf8;
package HiveWeb::Schema::Result::MemberPanel;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('member_panel');

__PACKAGE__->add_columns(
  'member_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'panel_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
	'visible',
  { data_type => 'boolean', is_nullable => 1 },
	'sort_order',
  { data_type => 'integer', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('member_id', 'panel_id');
__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);
__PACKAGE__->belongs_to(
  'panel',
  'HiveWeb::Schema::Result::Panel',
  { panel_id => 'panel_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

__PACKAGE__->meta->make_immutable;
1;
