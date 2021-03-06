use utf8;
package HiveWeb::Schema::Result::StorageSlot;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime Helper::Row::StorageValues });
__PACKAGE__->table('storage_slot');

__PACKAGE__->add_columns(
  'slot_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0, size => 32 },
  'member_id',
  {
	data_type          => 'uuid',
	is_nullable        => 1,
	keep_storage_value => 1,
	},
	'expire_date',
	{
	data_type          => 'timestamp with time zone',
	is_nullable        => 1,
	keep_storage_value => 1,
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

__PACKAGE__->has_many(
  'requests',
  'HiveWeb::Schema::Result::StorageRequest',
  { 'foreign.slot_id' => 'self.slot_id' },
  { is_deferrable => 0, cascade_copy => 0, cascade_delete => 0 },
);

sub update
	{
	my $self   = shift;
	my $schema = $self->result_source()->schema();
	my $guard  = $schema->txn_scope_guard();

	my $old_member_id   = $self->get_storage_value('member_id');
	my $old_expire_date = $self->get_storage_value('expire_date');

	my $res = $self->next::method(@_);
	$self->discard_changes();

	my $new_member_id   = $self->member_id();
	my $new_expire_date = $self->expire_date();

	if ($old_member_id && $old_member_id ne $new_member_id)
		{
		my $change = { changed_member_id => $old_member_id };
		if ($HiveWeb::Schema::member_id eq $old_member_id)
			{
			$change->{notes}       = 'Relinquished slot ' . $self->slot_id();
			$change->{change_type} = 'relinquish_slot';
			}
		else
			{
			$change->{change_type} = 'unassign_slot';
			$change->{notes}       = 'Unassigned slot ' . $self->slot_id();
			}
		$schema->resultset('AuditLog')->create($change);
		}

	if ($new_member_id && $old_member_id ne $new_member_id)
		{
		$schema->resultset('AuditLog')->create(
			{
			change_type       => 'assign_slot',
			notes             => 'Assigned slot ' . $self->slot_id(),
			changed_member_id => $new_member_id,
			});
		$schema->resultset('Action')->create(
			{
			action_type => 'storage.assign',
			row_id      => $self->slot_id(),
			}) || die 'Could not queue notification: ' . $!;
		}

	if ($new_member_id eq $old_member_id && DateTime->compare($old_expire_date, $new_expire_date))
		{
		$schema->resultset('AuditLog')->create(
			{
			change_type       => 'renew_slot',
			notes             => 'Renew slot ' . $self->slot_id(),
			changed_member_id => $new_member_id,
			});
		$schema->resultset('Action')->create(
			{
			action_type => 'storage.renew',
			row_id      => $self->slot_id(),
			}) || die 'Could not queue notification: ' . $!;
		}

	$guard->commit();
	return $res;
	}

sub TO_JSON
	{
	my $self = shift;
	my $type = $self->type();

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		member      => $self->member(),
		location_id => $self->location_id(),
		sort_order  => $self->sort_order(),
		type_id     => $self->type_id(),
		can_request => $type->can_request() ? \1 : \0,
		};
	}

sub TO_FULL_JSON
	{
	my $self = shift;
	my $type = $self->type();

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		member      => $self->member(),
		location_id => $self->location_id(),
		sort_order  => $self->sort_order(),
		type_id     => $self->type_id(),
		type        => $type,
		can_request => $type->can_request() ? \1 : \0,
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
