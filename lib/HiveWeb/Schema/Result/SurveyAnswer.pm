use utf8;
package HiveWeb::Schema::Result::SurveyAnswer;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('survey_answer');

__PACKAGE__->add_columns(
	'survey_answer_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'survey_response_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'survey_question_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'answer_text',
	{ data_type => 'character varying', is_nullable => 0, },
);

__PACKAGE__->set_primary_key('survey_answer_id');
__PACKAGE__->uuid_columns('survey_answer_id');
__PACKAGE__->resultset_attributes({ join => 'survey_question', order_by => 'survey_question.sort_order' });


__PACKAGE__->belongs_to(
	'survey_question',
	'HiveWeb::Schema::Result::SurveyQuestion',
	{ 'foreign.survey_question_id' => 'self.survey_question_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->belongs_to(
	'survey_response',
	'HiveWeb::Schema::Result::SurveyResponse',
	{ 'foreign.survey_response_id' => 'self.survey_response_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		survey_answer_id   => $self->survey_answer_id(),
		survey_response_id => $self->survey_response_id(),
		survey_question_id => $self->survey_question_id(),
		answer_text        => $self->answer_text(),
		};
	}
1;
