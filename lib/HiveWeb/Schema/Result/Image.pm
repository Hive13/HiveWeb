use utf8;
package HiveWeb::Schema::Result::Image;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("image");

__PACKAGE__->add_columns(
  "image_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "image",
  { data_type => "bytea", is_nullable => 0 },
  "thumbnail",
  { data_type => "bytea", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "updated_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
	'content_type',
	{ data_type => 'character varying', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('image_id');
__PACKAGE__->uuid_columns('image_id');

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;
1;
