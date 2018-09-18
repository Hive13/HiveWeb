use utf8;
package HiveWeb::Schema::Result::MemberMgroup;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('member_mgroup');

__PACKAGE__->add_columns(
  'member_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'mgroup_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
);

__PACKAGE__->set_primary_key('member_id', 'mgroup_id');
__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);
__PACKAGE__->belongs_to(
  'mgroup',
  'HiveWeb::Schema::Result::Mgroup',
  { mgroup_id => 'mgroup_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

__PACKAGE__->meta->make_immutable;
1;
