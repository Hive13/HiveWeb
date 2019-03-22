use utf8;
package HiveWeb::Schema::Result::SurveyChoice;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns });
__PACKAGE__->table('survey_choice');

__PACKAGE__->add_columns(
	'survey_choice_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'survey_question_id',
	{ data_type => 'uuid', is_nullable => 0, size => 16 },
	'sort_order',
	{ data_type => 'integer', is_nullable => 0, default_value => 1000 },
	'choice_name',
	{ data_type => 'character varying', is_nullable => 0 },
	'choice_text',
	{ data_type => 'character varying', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('survey_choice_id');
__PACKAGE__->uuid_columns('survey_choice_id');
__PACKAGE__->resultset_attributes({ order_by => [ 'sort_order', \'RAND()' ] });

__PACKAGE__->belongs_to(
	'question',
	'HiveWeb::Schema::Result::SurveyQuestion',
	{ 'foreign.survey_question_id' => 'self.survey_question_id' },
	{ is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;

	return
		{
		survey_choice_id => $self->survey_choice_id(),
		sort_order       => $self->sort_order(),
		choice_name      => $self->choice_name(),
		choice_text      => $self->choice_text(),
		};
	}
1;
