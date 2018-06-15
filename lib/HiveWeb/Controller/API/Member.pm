package HiveWeb::Controller::API::Member;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('find');
	}

sub find :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
	my $member;

	if ($in->{badge})
		{
		my $badge = $c->model('DB::Badge')->find({ badge_number => $in->{badge} });
		$member = $badge->member()
			if ($badge);
		}
	elsif (my $id = ($in->{member_id} // $in->{id}))
		{
		$member = $c->model('DB::Member')->find({ member_id => $id });
		}

	if (!$member)
		{
		$out->{response} = \0;
		$out->{error}    = 'Cannot find user.';
		return;
		}
	$out->{response} = \1;
	$out->{member}   =
		{
		fname  => $member->fname(),
		lname  => $member->lname(),
		handle => $member->handle(),
		};
	}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
