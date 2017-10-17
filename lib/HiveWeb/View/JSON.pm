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
	my $dt = shift;
	return $dt->iso8601() . 'Z';
	}

1;
