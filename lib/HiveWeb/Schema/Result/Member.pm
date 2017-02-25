use utf8;
package HiveWeb::Schema::Result::Member;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

use Crypt::Eksblowfish::Bcrypt qw* bcrypt *;

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("members");

__PACKAGE__->add_columns(
  "member_id",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "fname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "lname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "encrypted_password",
  { data_type => "varchar", is_nullable => 1, size => 255, accessor => 'password' },
  "accesscard",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "is_lockedout",
  { data_type => "boolean", is_nullable => 1 },
);

__PACKAGE__->uuid_columns('member_id');
__PACKAGE__->add_unique_constraint('index_members_on_email', ['email']);
__PACKAGE__->add_unique_constraint('members_member_id_key', ['member_id']);

__PACKAGE__->has_many
	(
	'access_logs',
	'HiveWeb::Schema::Result::AccessLog',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'badges',
	'HiveWeb::Schema::Result::Badge',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'member_mgroups',
	'HiveWeb::Schema::Result::MemberMgroup',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->many_to_many('mgroups', 'member_mgroups', 'mgroup');


sub check_password
	{
	my ($self, $pw) = @_;
	my $apw = $self->password();

	return ($apw eq bcrypt($pw, $apw));
	}

__PACKAGE__->meta->make_immutable;
1;
