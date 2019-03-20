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
__PACKAGE__->table('image');

__PACKAGE__->add_columns(
  'image_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'image',
  { data_type => 'bytea', is_nullable => 0 },
  'thumbnail',
  { data_type => 'bytea', is_nullable => 1 },
  'created_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
  },
  'updated_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
  },
	'content_type',
	{ data_type => 'character varying', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('image_id');
__PACKAGE__->uuid_columns('image_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { 'foreign.member_image_id' => 'self.image_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
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

	if (ref($attrs) eq 'HASH')
		{
		if (exists($attrs->{image}))
			{
			my $im = Image::Magick->new() || die $!;
			$im->BlobToImage($attrs->{image});
			$im->Resize(geometry => '100x100');
			$attrs->{thumbnail} = ($im->ImageToBlob())[0];
			}
		$attrs->{updated_at} = \'current_timestamp';
		}
	else
		{
		$attrs = { updated_at => \'current_timestamp' };
		}

	return $self->next::method($attrs);
	}

__PACKAGE__->meta->make_immutable;

sub attached_to
	{
	my $self   = shift;
	my $schema = $self->result_source()->schema();
	my $attachments =
		{
		member_id      => undef,
		application_id => undef,
		};

	my @member_ids = $schema->resultset('Member')->search({ member_image_id => $self->image_id() })->get_column('me.member_id')->all();
	$attachments->{member_id} = \@member_ids
		if (scalar(@member_ids) > 0);

	return $attachments;
	}

sub can_view
	{
	my ($self, $member) = @_;

	my $attachments = $self->attached_to();
	my $board       = $member
		->search_related('member_mgroups')
		->search_related('mgroup', { name => 'board' })
		->count();

	# Board can see all images
	return 1 if $board;

	# If it's attached to members, but not me, forbid
	return 0
		if (   ref($attachments->{member_id}) eq 'ARRAY'
		    && !(grep { $_ eq $member->member_id() } @{ $attachments->{member_id} }));

	# Default, allow to see
	return 1;
	}

1;
