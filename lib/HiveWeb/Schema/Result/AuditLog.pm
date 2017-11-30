use utf8;
package HiveWeb::Schema::Result::AuditLog;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("audit_log");

__PACKAGE__->add_columns(
  "audit_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "change_time",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "changed_member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "changing_member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "change_type",
  { data_type => "character varying", is_nullable => 0 },
  "notes",
  { data_type => "character varying", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("audit_id");
__PACKAGE__->uuid_columns(qw{ audit_id });

__PACKAGE__->belongs_to(
  "changing_member",
  "HiveWeb::Schema::Result::Member",
  { 'foreign.member_id' => 'self.changing_member_id' },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->belongs_to(
  "changed_member",
  "HiveWeb::Schema::Result::Member",
  { 'foreign.member_id' => 'self.changed_member_id' },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;
1;
