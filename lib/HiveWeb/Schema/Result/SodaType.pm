use utf8;
package HiveWeb::Schema::Result::SodaType;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

use Net::SMTP;

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table("soda_type");

__PACKAGE__->add_columns(
  "soda_type_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "character varying", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("soda_type_id");
__PACKAGE__->uuid_columns("soda_type_id");

__PACKAGE__->has_many(
  "soda_statuses",
  "HiveWeb::Schema::Result::SodaStatus",
  { "foreign.soda_type_id" => "self.soda_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		soda_type_id => $self->soda_type_id(),
		name         => $self->name(),
		};
	}

1;
