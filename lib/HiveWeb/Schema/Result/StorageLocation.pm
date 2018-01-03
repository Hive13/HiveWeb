use utf8;
package HiveWeb::Schema::Result::StorageLocation;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table("storage_location");

__PACKAGE__->add_columns(
  "location_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "parent_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "character varying", is_nullable => 0, size => 32 },
);

__PACKAGE__->set_primary_key("location_id");
__PACKAGE__->uuid_columns("location_id");

__PACKAGE__->has_many(
  "slots",
  "HiveWeb::Schema::Result::StorageSlot",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "children",
  "HiveWeb::Schema::Result::StorageLocation",
  { "foreign.parent_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "parent",
  "HiveWeb::Schema::Result::StorageLocation",
  { "foreign.location_id" => "self.parent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self     = shift;
	my @children = $self->children();
	my @slots    = $self->slots();

	return
		{
		storage_location_id => $self->location_id(),
		parent_id           => $self->parent_id(),
		name                => $self->name(),
		children            => \@children,
		slots               => \@slots,
		};
	}

1;
