use utf8;
package HiveWeb::Schema::Result::Purchase;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('purchase');

__PACKAGE__->add_columns(
	'purchase_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'member_id',
	{ data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
	'purchased_at',
	{ data_type => 'date', is_nullable => 0, default_value => \'CURRENT_DATE' },
);

__PACKAGE__->set_primary_key('purchase_id');
__PACKAGE__->uuid_columns('purchase_id');

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
		purchase_id   => $self->purchase_id(),
		purchase_date => $self->purchase_date(),
		};
	}

__PACKAGE__->meta->make_immutable;
1;
