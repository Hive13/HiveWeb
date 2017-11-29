use utf8;
package HiveWeb::Schema::Result::VendLog;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("vend_log");

__PACKAGE__->add_columns(
  "vend_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "vend_time",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "device_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "vended",
  { data_type => "boolean", is_nullable => 0 },
  "badge_id",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("vend_id");
__PACKAGE__->uuid_columns(qw{ vend_id device_id });

__PACKAGE__->belongs_to(
  "device",
  "HiveWeb::Schema::Result::Device",
  { device_id => "device_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;
1;
