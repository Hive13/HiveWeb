use utf8;
package HiveWeb::Schema::Result::SurveyResponse;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table('survey_response');

__PACKAGE__->add_columns(
	'survey_response_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'survey_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'member_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'created_at',
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

__PACKAGE__->set_primary_key('survey_response_id');
__PACKAGE__->uuid_columns('survey_response_id');

__PACKAGE__->belongs_to(
	'member',
	'HiveWeb::Schema::Result::Member',
	{ 'foreign.member_id' => 'self.member_id' },
);
__PACKAGE__->belongs_to(
	'survey',
	'HiveWeb::Schema::Result::Survey',
	{ 'foreign.survey_id' => 'self.survey_id' },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		survey_response_id => $self->survey_response_id(),
		survey_id          => $self->survey_id(),
		member_id          => $self->survey_id(),
		created_at         => $self->created_at(),
		};
	}
1;
