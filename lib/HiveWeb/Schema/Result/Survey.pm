use utf8;
package HiveWeb::Schema::Result::Survey;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('survey');

__PACKAGE__->add_columns(
	'survey_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'title',
	{ data_type => 'character varying', is_nullable => 1, },
);

__PACKAGE__->set_primary_key('survey_id');
__PACKAGE__->uuid_columns('survey_id');

__PACKAGE__->has_many(
	'questions',
	'HiveWeb::Schema::Result::SurveyQuestion',
	{ 'foreign.survey_id' => 'self.survey_id' },
);

__PACKAGE__->has_many(
	'responses',
	'HiveWeb::Schema::Result::SurveyResponse',
	{ 'foreign.survey_id' => 'self.survey_id' },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		survey_id => $self->survey_id(),
		title     => $self->title(),
		questions => $self->questions(),
		};
	}
1;
