use utf8;
package HiveWeb::Schema::Result::StorageLocation;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('storage_location');

__PACKAGE__->add_columns(
  'location_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'parent_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
	'sort_order',
	{ data_type => 'integer', is_nullable => 0, default_value => 1000 },
);

__PACKAGE__->set_primary_key('location_id');
__PACKAGE__->uuid_columns('location_id');
__PACKAGE__->resultset_attributes( { order_by => ['sort_order', 'name'] } );

__PACKAGE__->has_many(
  'slots',
  'HiveWeb::Schema::Result::StorageSlot',
  { 'foreign.location_id' => 'self.location_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  'children',
  'HiveWeb::Schema::Result::StorageLocation',
  { 'foreign.parent_id' => 'self.location_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'parent',
  'HiveWeb::Schema::Result::StorageLocation',
  { 'foreign.location_id' => 'self.parent_id' },
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
		location_id => $self->location_id(),
		parent_id   => $self->parent_id(),
		name        => $self->name(),
		sort_order  => $self->sort_order(),
		children    => \@children,
		slots       => \@slots,
		};
	}

sub TO_FULL_JSON
	{
	my $self     = shift;
	my @children = $self->children();
	my @slots    = $self->slots();
	my @ochildren;
	foreach my $child (@children)
		{
		push(@ochildren, $child->TO_FULL_JSON());
		}

	return
		{
		location_id => $self->location_id(),
		parent_id   => $self->parent_id(),
		name        => $self->name(),
		sort_order  => $self->sort_order(),
		children    => \@ochildren,
		slots       => \@slots,
		};
	}

1;
