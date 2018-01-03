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
  { data_type => 'text', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('request_id');
__PACKAGE__->uuid_columns('request_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { 'foreign.member_id' => 'self.member_id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		request_id => $self->request_id(),
		member_id  => $self->member_id(),
		created_at => $self->created_at(),
		notes      => $self->notes(),
		};
	}

1;
