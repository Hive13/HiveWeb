package HiveWeb::Controller::API::Image;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use Image::Magick;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private
	{
	my ($self, $c) = @_;

	my $image_id    = $c->stash()->{in}->{image_id} || return 1;
	my $image       = $c->model('DB::Image')->find($image_id) || die 'Invalid image ID';

	die 'Invalid image ID'
		if (!$image->can_view($c->user()));

	$c->stash({ image => $image });
	}

sub upload :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in    = $c->stash()->{in};
	my $out   = $c->stash()->{out};
	my $image = $c->request()->upload('photo');

	if (!$image)
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find image data.';
		return;
		}

	$out->{response} = \1;
	$out->{data}     = 'Picture uploaded.';
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $img_data = $image->slurp();
			my $im = Image::Magick->new() || die $!;
			$im->BlobToImage($img_data);
			$im->Resize(geometry => '100x100');
			my $thumb_data = ($im->ImageToBlob())[0];

			my $db_image = $c->model('DB::Image')->create(
				{
				image        => $img_data,
				thumbnail    => $thumb_data,
				content_type => $image->type(),
				}) || die $!;
			$out->{image_id} = $db_image->image_id();
			});
		}
	catch
		{
		delete($out->{image_id});
		$out->{response} = \0;
		$out->{data}     = 'Could not upload image: ' . $_;
		};
	}

sub rotate :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in       = $c->stash()->{in};
	my $out      = $c->stash()->{out};
	my $image_id = $in->{image_id};
	my $image    = $c->stash()->{image};
	my $degrees  = int($in->{degrees} || 90);

	$out->{image_id} = $image_id;
	$out->{response} = \1;
	$out->{data}     = 'Image updated.';
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $im = Image::Magick->new() || die $!;
			$im->BlobToImage($image->image());
			$im->Rotate(degrees => $degrees);
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

__PACKAGE__->meta->make_immutable;

1;
