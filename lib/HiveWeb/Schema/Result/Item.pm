use utf8;
package HiveWeb::Schema::Result::Item;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("item");

__PACKAGE__->add_columns(
  "item_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "char", is_nullable => 0, size => 32 },
);

__PACKAGE__->set_primary_key("item_id");

__PACKAGE__->has_many(
  "access_logs",
  "HiveWeb::Schema::Result::AccessLog",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "temp_logs",
  "HiveWeb::Schema::Result::TempLog",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "device_items",
  "HiveWeb::Schema::Result::DeviceItem",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "item_mgroups",
  "HiveWeb::Schema::Result::ItemMgroup",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many("devices", "device_items", "device");
__PACKAGE__->many_to_many("mgroups", "item_mgroups", "mgroup");

__PACKAGE__->meta->make_immutable;
1;
