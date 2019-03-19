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
__PACKAGE__->resultset_class('HiveWeb::DBIx::Class::ResultSet');

__PACKAGE__->add_columns(
  'payment_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
	'ipn_message_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
	'payment_date',
  {
    data_type     => 'timestamp with time zone',
    is_nullable   => 0,
    default_value => \'current_timestamp',
    original      => { default_value => \'now()' },
  },
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
  'ipn_message',
  'HiveWeb::Schema::Result::IPNMessage',
  { ipn_message_id => 'ipn_message_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		payment_id   => $self->payment_id(),
		member_id    => $self->member_id(),
		ipn_message  => $self->ipn_message(),
		payment_date => $self->payment_date(),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
