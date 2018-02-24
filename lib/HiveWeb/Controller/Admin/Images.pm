package HiveWeb::Controller::Admin::Images;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(1)
	{
	my $self     = shift;
	my $c        = shift;
	my $image_id = shift;

	my $image = $c->model('DB::Image')->find($image_id) // die;

	$c->response()->body($image->image());
	$c->response()->content_type($image->content_type());

	}

=encoding utf8

=head1 AUTHOR

Greg Arnold,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
