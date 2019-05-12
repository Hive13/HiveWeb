use utf8;
package HiveWeb::Schema::Result::Application;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime AutoUpdate });
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
		auto_update   => \'current_timestamp',
	},
	'app_turned_in_at',
	{
		data_type     => 'timestamp with time zone',
		default_value => undef,
		is_nullable   => 1,
	},
	'thread_message_id',
	{ data_type => 'character varying', is_nullable => 1, },
	'decided_at',
	{
		data_type     => 'timestamp with time zone',
		default_value => undef,
		is_nullable   => 1,
	},
	'final_result',
	{ data_type => 'character varying', is_nullable => 1, },
	'helper',
	{ data_type => 'character varying', is_nullable => 1, },
);

__PACKAGE__->set_primary_key('application_id');
__PACKAGE__->uuid_columns('application_id');

__PACKAGE__->belongs_to(
	'member',
	'HiveWeb::Schema::Result::Member',
	{ member_id => 'member_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->belongs_to(
	'form',
	'HiveWeb::Schema::Result::Image',
	{ 'foreign.image_id' => 'self.form_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->belongs_to(
	'picture',
	'HiveWeb::Schema::Result::Image',
	{ 'foreign.image_id' => 'self.picture_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

sub update
	{
	my $self   = shift;
	my $attrs  = shift;
	my $schema = $self->result_source()->schema();
	my %dirty  = $self->get_dirty_columns();
	my $ret    = $self->next::method($attrs, @_);

	if ($dirty{decided_at} || exists($attrs->{decided_at}))
		{
		$schema->resultset('Action')->create(
			{
			queuing_member_id => $HiveWeb::Schema::member_id,
			action_type       => 'application.finalize',
			row_id            => $self->application_id(),
			}) || die 'Could not queue notification: ' . $!;
		$schema->resultset('AuditLog')->create(
			{
			change_type       => 'finalize_application',
			notes             => 'Finalized Application ID ' . $self->application_id() . ' - ' . $self->final_result(),
			changed_member_id => $self->member_id(),
			}) || die 'Could not audit finalization: ' . $!;
		}

	return $self->next::method($attrs, @_);
	}

sub link_picture
	{
	my $self   = shift;
	my $schema = $self->result_source()->schema();
	$schema->txn_do(sub
		{
		my $member = $self->member();
		$member->create_related('changed_audits',
			{
			change_type => 'attach_photo_from_application',
			notes       => 'Attached image ID ' . $self->picture_id(),
			});
		$member->update({ member_image_id => $self->picture_id() });
		});
	}

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
		decided_at       => $self->decided_at(),
		final_result     => $self->final_result(),
		helper           => $self->helper(),
		};
	}
1;
