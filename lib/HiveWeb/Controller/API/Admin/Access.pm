package HiveWeb::Controller::API::Admin::Access;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub recent :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};
	
	my @accesses = $c->model('DB::AccessLog')->search({},
		{
		order_by => { -desc => 'me.access_time' },
		rows     => 10,
		prefetch => [ 'item', 'member' ],
		});
	$out->{accesses} = \@accesses;
	$out->{response} = \1;
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;
	
	$c->response->body('Matched HiveWeb::Controller::API in API.');
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
