use utf8;
package HiveWeb::Schema::Result::Log;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('log');

__PACKAGE__->add_columns(
  'log_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'create_time',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
  'type',
  { data_type => 'character varying', is_nullable => 0 },
  'message',
  { data_type => 'text', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('log_id');
__PACKAGE__->uuid_columns(qw{ log_id });

__PACKAGE__->meta->make_immutable;
1;
