use utf8;
package HiveWeb::Schema::Result::Device;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HiveWeb::Schema::Result::Device

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

=head1 TABLE: C<device>

=cut

__PACKAGE__->table("device");

=head1 ACCESSORS

=head2 device_id

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 key

  data_type: 'bytea'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "device_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "key",
  { data_type => "bytea", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</device_id>

=back

=cut

__PACKAGE__->set_primary_key("device_id");

=head1 RELATIONS

=head2 device_items

Type: has_many

Related object: L<HiveWeb::Schema::Result::DeviceItem>

=cut

__PACKAGE__->has_many(
  "device_items",
  "HiveWeb::Schema::Result::DeviceItem",
  { "foreign.device_id" => "self.device_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "vend_logs",
  "HiveWeb::Schema::Result::VendLog",
  { "foreign.device_id" => "self.device_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 items

Type: many_to_many

Composing rels: L</device_items> -> item

=cut

__PACKAGE__->many_to_many("items", "device_items", "item");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-02-24 20:22:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TvzxUAF5V3hRtM60SPzAmg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
