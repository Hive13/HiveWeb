package HiveWeb::View::JSON;

use strict;
use base 'Catalyst::View::JSON';
use JSON::PP;
use feature 'state';

=head1 NAME

HiveWeb::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<HiveWeb>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub encode_json
	{
	my($self, $c, $data) = @_;
	state $js  = JSON::PP->new();
	state $srt = sub { $JSON::PP::a cmp $JSON::PP::b; };
	
	return $js->sort_by($srt)->encode($data);
	}

1;
