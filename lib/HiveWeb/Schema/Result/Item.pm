use utf8;
package HiveWeb::Schema::Result::Item;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HiveWeb::Schema::Result::Item

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

=head1 TABLE: C<item>

=cut

__PACKAGE__->table("item");

=head1 ACCESSORS

=head2 item_id

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "item_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=back

=cut

__PACKAGE__->set_primary_key("item_id");

=head1 RELATIONS

=head2 access_logs

Type: has_many

Related object: L<HiveWeb::Schema::Result::AccessLog>

=cut

__PACKAGE__->has_many(
  "access_logs",
  "HiveWeb::Schema::Result::AccessLog",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_items

Type: has_many

Related object: L<HiveWeb::Schema::Result::DeviceItem>

=cut

__PACKAGE__->has_many(
  "device_items",
  "HiveWeb::Schema::Result::DeviceItem",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 item_mgroups

Type: has_many

Related object: L<HiveWeb::Schema::Result::ItemMgroup>

=cut

__PACKAGE__->has_many(
  "item_mgroups",
  "HiveWeb::Schema::Result::ItemMgroup",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 devices

Type: many_to_many

Composing rels: L</device_items> -> device

=cut

__PACKAGE__->many_to_many("devices", "device_items", "device");

=head2 mgroups

Type: many_to_many

Composing rels: L</item_mgroups> -> mgroup

=cut

__PACKAGE__->many_to_many("mgroups", "item_mgroups", "mgroup");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-02-24 20:22:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Nc/721iOPJAjKWmjP+Fkw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
