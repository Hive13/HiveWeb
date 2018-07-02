package HiveWeb::View::ChecksummedJSON;

use strict;
use base 'Catalyst::View::JSON';
use Digest::SHA qw(sha512_hex);
use JSON::PP;
use feature 'state';

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub encode_json
	{
	my($self, $c, $data) = @_;
	state $js    = JSON::PP->new();
	state $srt   = sub { $JSON::PP::a cmp $JSON::PP::b; };
	my $out_json = {};
	my $key      = $c->stash()->{device}->key();

	$out_json->{data} = $data;
	if (defined($key))
		{
		my $random = [];
		for (my $i = 0; $i < 16; $i++)
			{
			push(@{$random}, int(rand(256)));
			}
		$data->{random}       = $random;
		$out_json->{checksum} = $self->make_hash($c, $data);
		}

	return $js->sort_by($srt)->encode($out_json);
	}

sub make_hash
	{
	my ($self, $c, $data) = @_;
	state $js     = JSON::PP->new();
	state $sorter = sub { $JSON::PP::a cmp $JSON::PP::b; };
	my $key       = $c->stash()->{device}->key();
	my $hash_str  = $js->sort_by($sorter)->encode($data);

	return uc(sha512_hex($key . $hash_str));
	}

1;
