package HiveWeb::Controller::Image;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub get_image :Private
	{
	my ($self, $c, $image_id, $want_thumb) = @_;

	my $image       = $c->model('DB::Image')->find($image_id) // die 'Invalid image ID';
	my $response    = $c->response();
	my $attachments = $image->attached_to();

	# Board can see all images
	if (!$c->check_user_roles('board'))
		{
		# If it's attached to members, but not me, forbid
		die 'Invalid image ID'
			if (   ref($attachments->{member_id}) eq 'ARRAY'
			    && !(grep { $_ eq $c->user()->member_id() } @{ $attachments->{member_id} }));
		}

	$response->body($want_thumb ? ($image->thumbnail() || $image->image()) : $image->image());
	$response->content_type($image->content_type());
	$response->header('Cache-Control' => 'max-age=0, must-revalidate');
	}

sub index :Path :Args(1)
	{
	return shift->get_image(@_, 0);
	}

sub thumb :Local :Args(1)
	{
	return shift->get_image(@_, 1);
	}

__PACKAGE__->meta->make_immutable;

1;
