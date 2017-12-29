use utf8;
package HiveWeb::Schema::Result::Mgroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HiveWeb::Schema::Result::Mgroup

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("mgroup");

__PACKAGE__->add_columns(
  "mgroup_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "char", is_nullable => 1, size => 32 },
);

__PACKAGE__->set_primary_key("mgroup_id");

__PACKAGE__->has_many(
  "item_mgroups",
  "HiveWeb::Schema::Result::ItemMgroup",
  { "foreign.mgroup_id" => "self.mgroup_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "member_mgroups",
  "HiveWeb::Schema::Result::MemberMgroup",
  { "foreign.mgroup_id" => "self.mgroup_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many("items", "item_mgroups", "item");
__PACKAGE__->many_to_many("members", "member_mgroups", "member");

sub TO_JSON
	{
	my $self    = shift;
	my $columns = { $self->get_columns() };

	return
		{
		name      => $self->name(),
		mgroup_id => $self->mgroup_id(),
		( exists($columns->{mcount}) ? ( mcount => $columns->{mcount} ) : () ),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
