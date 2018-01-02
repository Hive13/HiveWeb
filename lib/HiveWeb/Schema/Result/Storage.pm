use utf8;
package HiveWeb::Schema::Result::Storage;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("storage");

__PACKAGE__->add_columns(
  "storage_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "character varying", is_nullable => 0, size => 32 },
  "member_id",
  { data_type => "uuid", is_nullable => 1 },
  "storage_location_id",
  { data_type => "uuid", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("storage_id");
__PACKAGE__->uuid_columns("storage_id");

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { "foreign.member_id" => "self.member_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "location",
  "HiveWeb::Schema::Result::StorageLocation",
  { "foreign.storage_location_id" => "self.storage_location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		storage_id  => $self->storage_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		location_id => $self->storage_location_id(),
		};
	}
1;
