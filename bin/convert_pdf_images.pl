#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;
use Image::Magick;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $candidates = $schema->resultset('Image')->search({ content_type => 'application/pdf' });

while (my $pdf = $candidates->next())
	{
	$schema->txn_do(sub
		{
		my $im = Image::Magick->new();
		$im->BlobToImage($pdf->image());
		$im->Set(filename => 'junk.png');
		my $out = ($im->ImageToBlob(format => 'png'))[0];
		$pdf->update({ image => $out, content_type => 'image/png' });
		});
	}
