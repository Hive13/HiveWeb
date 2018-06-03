package HiveWeb::Controller::API::Heatmap;
use Moose;
use namespace::autoclean;

use Math::Round;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('accesses');
	}

sub accesses :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out = $c->stash()->{out};

	my $dow = [];
	my $max = 0;
	my $heatmap = $c->model('DB::AccessHeatmap')->search({});

	for (my $i = 0; $i < 7; $i++)
		{
		my $qhour = [];
		for (my $j = 0; $j < (24 * 4); $j++)
			{
			push(@$qhour, 0);
			}
		push(@$dow, $qhour);
		}

	while (my $entry = $heatmap->next())
		{
		my $column = $entry->hour() * 4 + $entry->qhour();
		my $value  = $entry->access_count();
		$max = $value
			if ($max < $value);
		$dow->[$entry->dow()]->[$column] = $value;
		}

	for (my $i = 0; $i < 7; $i++)
		{
		for (my $j = 0; $j < (24 * 4); $j++)
			{
			my $v = ($dow->[$i]->[$j] * 100) / $max;
			$dow->[$i]->[$j] = round($v);
			}
		}

	$out->{accesses} = $dow;
	$out->{response} = \1;
	}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
