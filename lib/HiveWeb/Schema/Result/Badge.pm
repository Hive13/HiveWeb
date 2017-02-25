use utf8;
package HiveWeb::Schema::Result::Badge;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HiveWeb::Schema::Result::Badge

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<badge>

=cut

__PACKAGE__->table("badge");

=head1 ACCESSORS

=head2 badge_id

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 badge_number

  data_type: 'integer'
  is_nullable: 0

=head2 member_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "badge_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "badge_number",
  { data_type => "integer", is_nullable => 0 },
  "member_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</badge_id>

=back

=cut

__PACKAGE__->set_primary_key("badge_id");

=head1 RELATIONS

=head2 member

Type: belongs_to

Related object: L<HiveWeb::Schema::Result::Member>

=cut

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { member_id => "member_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-02-24 20:22:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:27pB5+2kzG6MT2TsJAl1pw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
