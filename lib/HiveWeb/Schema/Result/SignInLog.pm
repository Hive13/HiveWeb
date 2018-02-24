use utf8;
package HiveWeb::Schema::Result::SignInLog;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("sign_in_log");

__PACKAGE__->add_columns(
  "sign_in_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "sign_in_time",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "valid",
  { data_type => "boolean", is_nullable => 1 },
  "remote_ip",
  { data_type => "inet", is_nullable => 0 },
  "email",
  { data_type => "character varying", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("sign_in_id");
__PACKAGE__->uuid_columns(qw{ sign_in_id });

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;
1;
