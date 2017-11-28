use utf8;
package HiveWeb::Schema::Result::ResetToken;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("reset_token");

__PACKAGE__->add_columns(
  "token_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "created_at",
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
);

__PACKAGE__->set_primary_key("token_id");
__PACKAGE__->uuid_columns(qw{ token_id });

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;
1;
