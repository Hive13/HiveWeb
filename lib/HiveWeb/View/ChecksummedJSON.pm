package HiveWeb::View::ChecksummedJSON;

use strict;
use base 'Catalyst::View::JSON';
use Digest::SHA qw(sha512_hex);
use JSON ();

my $js = JSON->new()->canonical();

sub encode_json
	{
	my($self, $c, $data) = @_;
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

	return $js->encode($out_json);
	}

sub make_hash
	{
	my ($self, $c, $data) = @_;
	my $key       = $c->stash()->{device}->key();
	my $hash_str  = $js->encode($data);

	return uc(sha512_hex($key . $hash_str));
	}

1;
