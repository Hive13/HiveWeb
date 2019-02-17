use utf8;
package HiveWeb::Schema::Result::IPNMessage;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'HiveWeb::DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('ipn_message');

__PACKAGE__->add_columns(
  'ipn_message_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
	'received_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
	'txn_id',
  { data_type => 'character varying', is_nullable => 1 },
	'payer_email',
  { data_type => 'character varying', is_nullable => 0 },
	'raw',
  { data_type => 'text', is_nullable => 0 },
);

__PACKAGE__->uuid_columns('ipn_message_id');
__PACKAGE__->set_primary_key('ipn_message_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		ipn_message_id => $self->ipn_message_id(),
		member_id      => $self->member_id(),
		received_at    => $self->received_at(),
		txn_id         => $self->txn_id(),
		payer_email    => $self->payer_email(),
		data           => eval($self->raw()),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
