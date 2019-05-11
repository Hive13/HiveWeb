use utf8;
package HiveWeb::Schema::Result::Action;

use strict;
use warnings;

use HiveWeb;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('action');

__PACKAGE__->add_columns(
	'action_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'queued_at',
	{
		data_type     => 'timestamp with time zone',
		default_value => \'current_timestamp',
		is_nullable   => 0,
	},
	'queuing_member_id',
	{ data_type => 'uuid', is_nullable => 0, is_foreign_key => 1, size => 16 },
	'priority',
	{ data_type => 'interger', is_nullable => 0, default_value => 1000 },
	'action_type',
	{ data_type => 'character varying', is_nullable => 0, },
	'row_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
);

__PACKAGE__->set_primary_key('action_id');
__PACKAGE__->uuid_columns('action_id');

__PACKAGE__->belongs_to(
	'queuing_member',
	'HiveWeb::Schema::Result::Member',
	{ member_id => 'queuing_member_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

sub new
	{
	my ($self, $attrs)   = @_;
	my $c                = HiveWeb->new;
	$attrs->{priority} //= $c->config_path('email.' . $attrs->{action_type}, 'priority') // 1000;

	return $self->next::method($attrs);
	}

sub TO_JSON
	{
	my $self = shift;

	return
		{
		action_id      => $self->application_id(),
		queued_at      => $self->queued_at(),
		queuing_member => $self->queuing_member(),
		priority       => $self->priority(),
		action_type    => $self->action_type(),
		row_id         => $self->row_id(),
		};
	}
1;
