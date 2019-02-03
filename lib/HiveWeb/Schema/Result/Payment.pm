use utf8;
package HiveWeb::Schema::Result::Payment;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'HiveWeb::DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('payment');

__PACKAGE__->add_columns(
  'payment_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'payment_type_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
	'payment_date',
  {
    data_type     => 'timestamp with time zone',
    is_nullable   => 0,
  },
	'processed_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
  'payment_currency',
  { data_type => 'character varying', is_nullable => 0 },
  'payment_amount',
  { data_type => 'numeric', is_nullable => 0 },
	'paypal_txn_id',
  { data_type => 'character varying', is_nullable => 0 },
	'payer_email',
  { data_type => 'character varying', is_nullable => 0 },
	'raw',
  { data_type => 'text', is_nullable => 0 },
);

__PACKAGE__->uuid_columns('payment_id');
__PACKAGE__->set_primary_key('payment_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

__PACKAGE__->belongs_to(
  'payment_type',
  'HiveWeb::Schema::Result::PaymentType',
  { payment_type_id => 'payment_type_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		payment_id   => $self->payment_id(),
		payment_type => $self->payment_type(),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
