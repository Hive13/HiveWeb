use utf8;
package HiveWeb::Schema::Result::ItemMgroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HiveWeb::Schema::Result::ItemMgroup

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<item_mgroup>

=cut

__PACKAGE__->table("item_mgroup");

=head1 ACCESSORS

=head2 item_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 mgroup_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "item_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "mgroup_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=item * L</mgroup_id>

=back

=cut

__PACKAGE__->set_primary_key("item_id", "mgroup_id");

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<HiveWeb::Schema::Result::Item>

=cut

__PACKAGE__->belongs_to(
  "item",
  "HiveWeb::Schema::Result::Item",
  { item_id => "item_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 mgroup

Type: belongs_to

Related object: L<HiveWeb::Schema::Result::Mgroup>

=cut

__PACKAGE__->belongs_to(
  "mgroup",
  "HiveWeb::Schema::Result::Mgroup",
  { mgroup_id => "mgroup_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-02-24 20:22:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xhoT1FIZcS6slSfKU5O3Dw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
