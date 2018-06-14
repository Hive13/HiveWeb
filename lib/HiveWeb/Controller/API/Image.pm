package HiveWeb::Controller::API::Image;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use Image::Magick;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private
	{
	my ($self, $c) = @_;

	my $image_id    = $c->stash()->{in}->{image_id};
	my $image       = $c->model('DB::Image')->find($image_id) || die 'Invalid image ID';
	my $attachments = $image->attached_to();

	# Board can see all images
	if (!$c->check_user_roles('board'))
		{
		# If it's attached to members, but not me, forbid
		die 'Invalid image ID'
			if (   ref($attachments->{member_id}) eq 'ARRAY'
			    && !(grep { $_ eq $c->user()->member_id() } @{ $attachments->{member_id} }));
		}
	
	$c->stash({ image => $image });
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
