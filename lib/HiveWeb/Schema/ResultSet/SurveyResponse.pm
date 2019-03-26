package HiveWeb::Schema::ResultSet::SurveyResponse;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub fill_out
	{
	my ($self, $member_id, $survey, $form) = @_;
	my $schema = $self->result_source()->schema();

	$member_id = $member_id->member_id() if (ref($member_id));
	if (!ref($survey))
		{
		$survey = $schema->resultset('Survey')->find($survey) || die 'No such survey.';
		}
	
	my $response;
	
	$schema->txn_do(sub
		{
		$response = $survey->create_related('responses', { member_id => $member_id }) || die $!;

		my @questions = $survey->questions();
		foreach my $question (@questions)
			{
			my $answer = $form->{ $question->survey_question_id() };
			next if (!defined($answer));
			$question->create_related('answers',
				{
				survey_response_id => $response->survey_response_id(),
				answer_text        => $answer,
				}) || die $!;
			}
		});
	return $response;
	}

1;
