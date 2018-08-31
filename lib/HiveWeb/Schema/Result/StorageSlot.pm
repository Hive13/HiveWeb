use utf8;
package HiveWeb::Schema::Result::StorageSlot;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

use Net::SMTP;

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("storage_slot");

__PACKAGE__->add_columns(
  "slot_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "character varying", is_nullable => 0, size => 32 },
  "member_id",
  { data_type => "uuid", is_nullable => 1 },
  "location_id",
  { data_type => "uuid", is_nullable => 0 },
  "sort_order",
  { data_type => "integer", is_nullable => 0, default_value => 1000 },
);

__PACKAGE__->set_primary_key("slot_id");
__PACKAGE__->uuid_columns("slot_id");
__PACKAGE__->resultset_attributes( { order_by => ['sort_order', 'name'] } );

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { "foreign.member_id" => "self.member_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "location",
  "HiveWeb::Schema::Result::StorageLocation",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub assign
	{
	my ($self, $member_id, $assigning_member_id) = @_;
	my $schema = $self->result_source()->schema();

	return
		if (!$member_id || !$assigning_member_id);
	$member_id = $member_id->member_id()
		if (ref($member_id));
	$assigning_member_id = $assigning_member_id->member_id()
		if (ref($assigning_member_id));

	$schema->txn_do(sub
		{
		$schema->resultset('Action')->create(
			{
			action_type       => 'storage.assign',
			queuing_member_id => $assigning_member_id,
			row_id            => $self->slot_id(),
			}) || die 'Could not queue notification: ' . $!;
		$self->update({ member_id => $member_id }) || die $!;
		});
	}

sub TO_JSON
	{
	my $self = shift;

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		member      => $self->member(),
		location_id => $self->location_id(),
		sort_order  => $self->sort_order(),
		};
	}

sub TO_FULL_JSON
	{
	my $self = shift;

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		member      => $self->member(),
		location_id => $self->location_id(),
		location    => $self->location(),
		sort_order  => $self->sort_order(),
		};
	}

sub hierarchy
	{
	my $self = shift;
	my $sep  = shift // '&rarr;';

	my $lname;
	my $location = $self->location();
	while ($location)
		{
		$lname = " $sep $lname"
			if ($lname);
		$lname = $location->name() . $lname;
		$location = $location->parent();
		}

	return $lname;
	}
1;
