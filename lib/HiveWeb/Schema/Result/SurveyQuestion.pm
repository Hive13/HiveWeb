use utf8;
package HiveWeb::Schema::Result::SurveyQuestion;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('survey_question');

__PACKAGE__->add_columns(
	'survey_question_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'survey_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
  'sort_order',
  { data_type => 'integer', is_nullable => 0, default_value => 1000 },
	'question_text',
	{ data_type => 'character varying', is_nullable => 0, },
);

__PACKAGE__->set_primary_key('survey_question_id');
__PACKAGE__->uuid_columns('survey_question_id');
__PACKAGE__->resultset_attributes({ order_by => 'sort_order' });

__PACKAGE__->belongs_to(
	'survey',
	'HiveWeb::Schema::Result::Survey',
	{ 'foreign.survey_id' => 'self.survey_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->has_many(
	'answers',
	'HiveWeb::Schema::Result::SurveyAnswer',
	{ 'foreign.survey_question_id' => 'self.survey_question_id' },
);
__PACKAGE__->has_many(
	'choices',
	'HiveWeb::Schema::Result::SurveyChoice',
	{ 'foreign.survey_question_id' => 'self.survey_question_id' },
);


__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		survey_question_id => $self->survey_question_id(),
		sort_order         => $self->sort_order(),
		question_text      => $self->question_text(),
		};
	}
1;
