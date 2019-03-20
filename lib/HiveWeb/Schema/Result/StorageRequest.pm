use utf8;
package HiveWeb::Schema::Result::StorageRequest;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('storage_request');

__PACKAGE__->add_columns(
  'request_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'created_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
	},
  'notes',
  { data_type => 'text', is_nullable => 1 },
  'status',
  { data_type => 'character varying', is_nullable => 0, default_value => 'requested' },
  'slot_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
  'deciding_member_id',
  { data_type => 'uuid', is_nullable => 1 },
  'decision_notes',
  { data_type => 'text', is_nullable => 1 },
  'decided_at',
  {
    data_type     => 'timestamp with time zone',
    is_nullable   => 1,
	},
	'hidden',
	{
		data_type     => 'boolean',
		is_nullable   => 0,
		default_value => 'f',
	},
	'type_id',
	{
		data_type      => 'uuid',
		is_nullable    => 0,
		is_foreign_key => 1,
	},
);

__PACKAGE__->set_primary_key('request_id');
__PACKAGE__->uuid_columns('request_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { 'foreign.member_id' => 'self.member_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'deciding_member',
  'HiveWeb::Schema::Result::Member',
  { 'foreign.member_id' => 'self.deciding_member_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'slot',
  'HiveWeb::Schema::Result::StorageSlot',
  { 'foreign.slot_id' => 'self.slot_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  'type',
  'HiveWeb::Schema::Result::StorageSlotType',
  { 'foreign.type_id' => 'self.type_id' },
  { is_deferrable => 0, cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		request_id     => $self->request_id(),
		member_id      => $self->member_id(),
		created_at     => $self->created_at(),
		notes          => $self->notes(),
		status         => $self->status(),
		decided_at     => $self->decided_at(),
		decision_notes => $self->decision_notes(),
		hidden         => $self->hidden() ? \1 : \0,
		type_id        => $self->type_id(),
		};
	}

sub TO_FULL_JSON
	{
	my $self   = shift;
	my $member = $self->member();
	my @slots;
	foreach my $slot ($member->slots)
		{
		my $hierarchy = [];
		my $location = $slot->location();
		while ($location)
			{
			unshift(@$hierarchy, $location->name());
			$location = $location->parent();
			}

		push(@slots,
			{
			slot_id   => $slot->slot_id(),
			name      => $slot->name(),
			hierarchy => $hierarchy
			});
		}

	return
		{
		request_id  => $self->request_id(),
		member      =>
			{
			member_id       => $member->member_id(),
			fname           => $member->fname(),
			lname           => $member->lname(),
			email           => $member->email(),
			handle          => $member->handle(),
			},
		other_slots => \@slots,
		created_at  => $self->created_at(),
		notes       => $self->notes(),
		hidden      => $self->hidden() ? \1 : \0,
		type_id     => $self->type_id(),
		type        => $self->type(),
		};
	}

1;
