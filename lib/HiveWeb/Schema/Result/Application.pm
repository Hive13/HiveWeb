use utf8;
package HiveWeb::Schema::Result::Application;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('application');

__PACKAGE__->add_columns(
	'application_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'member_id',
	{ data_type => 'uuid', is_nullable => 0, is_foreign_key => 1, size => 16 },
	'address1',
	{ data_type => 'character varying', is_nullable => 0, },
	'address2',
	{ data_type => 'character varying', is_nullable => 1, },
	'city',
	{ data_type => 'character varying', is_nullable => 0, },
	'state',
	{ data_type => 'character', is_nullable => 0, size => 2, },
	'zip',
	{ data_type => 'character', is_nullable => 0, size => 9, },
	'contact_name',
	{ data_type => 'character varying', is_nullable => 1, },
	'contact_phone',
	{ data_type => 'bigint', is_nullable => 1, },
	'form_id',
	{ data_type => 'uuid', is_nullable => 1, size => 16 },
	'topic_id',
	{ data_type => 'character varying', is_nullable => 1, },
	'picture_id',
	{ data_type => 'uuid', is_nullable => 1, size => 16 },
	'created_at',
	{
		data_type     => 'timestamp without time zone',
		default_value => \'current_timestamp',
		is_nullable   => 0,
		original      => { default_value => \'now()' },
	},
	'updated_at',
	{
		data_type     => 'timestamp without time zone',
		default_value => \'current_timestamp',
		is_nullable   => 0,
		original      => { default_value => \'now()' },
	},
	'app_turned_in_at',
	{
		data_type     => 'timestamp with time zone',
		default_value => undef,
		is_nullable   => 1,
	},
);

__PACKAGE__->set_primary_key('application_id');
__PACKAGE__->uuid_columns('application_id');

__PACKAGE__->belongs_to(
	'member',
	'HiveWeb::Schema::Result::Member',
	{ member_id => 'member_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		application_id   => $self->application_id(),
		member           => $self->member(),
		address1         => $self->address1(),
		address2         => $self->address2(),
		city             => $self->city(),
		state            => $self->state(),
		zip              => $self->zip(),
		contact_name     => $self->contact_name(),
		contact_phone    => $self->contact_phone(),
		form_id          => $self->form_id(),
		topic_id         => $self->topic_id(),
		picture_id       => $self->picture_id(),
		created_at       => $self->created_at(),
		updated_at       => $self->updated_at(),
		app_turned_in_at => $self->app_turned_in_at(),
		};
	}
1;
