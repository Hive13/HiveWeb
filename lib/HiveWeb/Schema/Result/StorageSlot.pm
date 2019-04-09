use utf8;
package HiveWeb::Schema::Result::StorageSlot;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime +HiveWeb::DBIx::Class::OnUpdate });
__PACKAGE__->table('storage_slot');

__PACKAGE__->add_columns(
  'slot_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'member_id',
  { data_type => 'uuid', is_nullable => 1, on_update => 'update_member' },
	'expire_date',
	{
	data_type   => 'timestamp with time zone',
	is_nullable => 1,
	},
  'location_id',
  { data_type => 'uuid', is_nullable => 0 },
	'type_id',
  { data_type => 'uuid', is_nullable => 0, is_foreign_key => 1 },
  'sort_order',
  { data_type => 'integer', is_nullable => 0, default_value => 1000 },
);

__PACKAGE__->set_primary_key('slot_id');
__PACKAGE__->uuid_columns('slot_id');
__PACKAGE__->resultset_attributes( { order_by => ['sort_order', 'name'] } );

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { 'foreign.member_id' => 'self.member_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'location',
  'HiveWeb::Schema::Result::StorageLocation',
  { 'foreign.location_id' => 'self.location_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'type',
  'HiveWeb::Schema::Result::StorageSlotType',
  { 'foreign.type_id' => 'self.type_id' },
  { is_deferrable => 0, cascade_copy => 0, cascade_delete => 0 },
);

sub update_member
	{
	my ($self, $old, $new) = @_;
	my $schema = $self->result_source()->schema();

	$schema->txn_do(sub
		{
		if ($old)
			{
			$schema->resultset('AuditLog')->create(
				{
				change_type        => 'unassign_slot',
				notes              => 'Unassigned slot ' . $self->slot_id(),
				changing_member_id => $HiveWeb::Schema::member_id,
				changed_member_id  => $old,
				}) || die $!;
			}
		if ($new)
			{
			$schema->resultset('AuditLog')->create(
				{
				change_type        => 'assign_slot',
				notes              => 'Assigned slot ' . $self->slot_id(),
				changed_member_id  => $new,
				changing_member_id => $HiveWeb::Schema::member_id,
				});
			$schema->resultset('Action')->create(
				{
				action_type       => 'storage.assign',
				queuing_member_id => $HiveWeb::Schema::member_id,
				row_id            => $self->slot_id(),
				}) || die 'Could not queue notification: ' . $!;
			}
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
		type_id     => $self->type_id(),
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
		sort_order  => $self->sort_order(),
		type_id     => $self->type_id(),
		type        => $self->type(),
		};
	}

sub assign
	{
	my ($self, $member_id) = @_;

	$member_id = $member_id->member_id() if (ref($member_id));
	my $schema = $self->result_source()->schema();
	$schema->txn_do(sub
		{
		my $cols = { member_id => $member_id };
		my $type = $self->type();
		if (defined(my $i = $type->default_expire_time()))
			{
			$cols->{expire_date} = \['now() + ?', $i];
			}
		$self->update($cols) || (warn $! && die $!);
		});
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
