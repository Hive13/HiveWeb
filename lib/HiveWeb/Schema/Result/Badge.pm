use utf8;
package HiveWeb::Schema::Result::Badge;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("badge");

__PACKAGE__->add_columns(
	"badge_id",
	{ data_type => "uuid", is_nullable => 0, size => 16 },
	"badge_number",
	{ data_type => "integer", is_nullable => 0 },
	"member_id",
	{ data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

__PACKAGE__->set_primary_key("badge_id");
__PACKAGE__->uuid_columns('badge_id');

__PACKAGE__->belongs_to(
	"member",
	"HiveWeb::Schema::Result::Member",
	{ member_id => "member_id" },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

sub insert
  {
	my $self   = shift;

	$self->result_source()->schema->resultset('AuditLog')->create(
		{
		change_type       => 'add_badge',
		notes             => 'Badge number ' . $self->badge_number,
		changed_member_id => $self->member_id(),
		});

	return $self->next::method(@_);
	}

sub delete
	{
	my $self = shift;

	$self->result_source()->schema->resultset('AuditLog')->create(
		{
		changed_member_id => $self->member_id(),
		change_type       => 'delete_badge',
		notes             => 'Badge number ' . $self->badge_number(),
		});

	return $self->next::method(@_);
	}

sub TO_JSON
	{
	my $self = shift;

	return
		{
		badge_id     => $self->badge_id(),
		badge_number => $self->badge_number(),
		};
	}

1;
