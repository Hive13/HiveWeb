use utf8;
package HiveWeb::Schema::Result::Image;

use strict;
use warnings;

use Image::Magick;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("image");

__PACKAGE__->add_columns(
  "image_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "image",
  { data_type => "bytea", is_nullable => 0 },
  "thumbnail",
  { data_type => "bytea", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "updated_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
	'content_type',
	{ data_type => 'character varying', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('image_id');
__PACKAGE__->uuid_columns('image_id');

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { 'foreign.member_image_id' => 'self.image_id' },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

#Automatically generate thumbnails
#sub new
	#{
	#my $self  = shift;
	#my $attrs = shift;

	#if (exists($attrs->{image}))
	#	{
	#	my $im = Image::Magick->new() || die $!;
	#	$im->BlobToImage($attrs->{image}) || die $!;
	#	$im->Resize(geometry => '100x100') || die $!;
	#	$attrs->{thumbnail} = ($im->ImageToBlob())[0];
	#	}

	#return $self->next::method($attrs);
	#}

sub update
	{
	my $self  = shift;
	my $attrs = shift;

	if (ref($attrs) eq 'HASH' && exists($attrs->{image}))
		{
		my $im = Image::Magick->new() || die $!;
		$im->BlobToImage($attrs->{image}) || die $!;
		$im->Resize(geometry => '100x100') || die $!;
		$attrs->{thumbnail} = ($im->ImageToBlob())[0];
		}

	return $self->next::method($attrs);
	}

__PACKAGE__->meta->make_immutable;

1;
