use utf8;
package HiveWeb::Schema::Result::AccessLog;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("access_log");

__PACKAGE__->add_columns(
  "access_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "access_time",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "item_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "granted",
  { data_type => "boolean", is_nullable => 0 },
  "badge_id",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("access_id");
__PACKAGE__->uuid_columns(qw{ access_id item_id });

__PACKAGE__->belongs_to(
  "item",
  "HiveWeb::Schema::Result::Item",
  { item_id => "item_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		access_id    => $self->access_id(),
		access_time  => $self->access_time(),
		item         => $self->item(),
		member       => $self->member(),
		granted      => $self->granted() ? \1 : \0,
		badge_number => $self->badge_id(),
		};
	}
1;
