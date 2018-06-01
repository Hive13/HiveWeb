package HiveWeb::Controller::API::Admin::Images;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use DateTime;
use Image::Magick;

BEGIN { extends 'Catalyst::Controller'; }

sub rotate :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in       = $c->stash()->{in};
	my $out      = $c->stash()->{out};
	my $image_id = $in->{image_id};
	my $image    = $c->model('DB::Image')->find($image_id);

	if (!defined($image))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find image";
		return;
		}

	$out->{image_id} = $image_id;
	$out->{response} = \1;
	$out->{data}     = 'Image updated.';
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $im = Image::Magick->new() || die $!;
			$im->BlobToImage($image->image());
			$im->Rotate(degrees => 90);
			my $data = ($im->ImageToBlob())[0];
			$image->update({ image => $data }) || die $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update image: ' . $_;
		};
	}

=encoding utf8

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
