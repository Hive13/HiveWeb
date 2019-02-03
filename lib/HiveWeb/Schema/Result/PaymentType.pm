use utf8;
package HiveWeb::Schema::Result::PaymentType;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'HiveWeb::DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('payment_type');

__PACKAGE__->add_columns(
  'payment_type_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'name',
  { data_type => 'character varying', is_nullable => 0 },
);

__PACKAGE__->uuid_columns('payment_type_id');
__PACKAGE__->set_primary_key('payment_type_id');

__PACKAGE__->has_many
	(
	'payments',
	'HiveWeb::Schema::Result::Payment',
	{ 'foreign.payment_type_id' => 'self.payrment_type_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		payment_type_id => $self->payment_type_id(),
		name            => $self->name(),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
