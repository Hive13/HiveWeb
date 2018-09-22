use utf8;
package HiveWeb::Schema::Result::TempLog;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('temp_log');

__PACKAGE__->add_columns(
  'temp_log_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'create_time',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
  'item_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'temperature',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('temp_log_id');
__PACKAGE__->uuid_columns(qw{ temp_log_id item_id });

__PACKAGE__->belongs_to(
  'item',
  'HiveWeb::Schema::Result::Item',
  { item_id => 'item_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

sub sqlt_deploy_hook
	{
	my ($self, $sqlt_table) = @_;

	$sqlt_table->add_index(name => 'recent_temp', fields => ['item_id', 'create_time']);
	}

sub TO_JSON
	{
	my $self = shift;
	my $item = $self->item();

	return
		{
		display_name => $item->display_name(),
		name         => $item->name(),
		value        => $self->temperature() / 10,
		};
	}

__PACKAGE__->meta->make_immutable;
1;
