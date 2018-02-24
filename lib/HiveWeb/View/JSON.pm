package HiveWeb::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub DateTime::TO_JSON
	{
	my $dt     = shift;
	my $offset = $dt->offset() || 0;
	my $tz     = 'Z';

	if ($offset)
		{
		my $h = $offset / 3600;
		my $m = ($offset % 3600) / 60;
		$tz = sprintf('%+03d:%02d', $h, $m);
		}

	return $dt->iso8601() . $tz;
	}

1;
