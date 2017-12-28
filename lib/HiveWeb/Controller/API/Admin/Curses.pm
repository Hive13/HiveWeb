package HiveWeb::Controller::API::Admin::Curses;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};

	my @curses = $c->model('DB::Curse')->all();

	$out->{response} = \1;
	$out->{curses}   = \@curses;
	}

sub cast :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};

	my $member = $c->model('DB::Member')->find({ member_id => $in->{member_id} });
	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member " . $in->{member_id};
		return;
		}
	my $curse = $c->model('DB::Curse')->find({ curse_id => $in->{curse_id} });
	if (!defined($curse))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find curse " . $in->{curse_id};
		return;
		}

	my $mc = $c->model('DB::MemberCurse')->find(
		{
		member_id => $in->{member_id},
		curse_id  => $in->{curse_id},
		issued_at => { '<=' => \'now()' },
		lifted_at => [ { '>=' => \'now()' }, undef ],
		});
	if ($mc)
		{
		$out->{response}        = \0;
		$out->{data}            = "That member already has that curse active.";
		$out->{member_curse_id} = $mc->member_curse_id();
		return;
		}

	$mc = $c->model('DB::MemberCurse')->create(
		{
		member_id         => $in->{member_id},
		curse_id          => $in->{curse_id},
		issuing_member_id => $c->user()->member_id(),
		issuing_notes     => $in->{notes},
		}) || die $!;

	$out->{response}        = \1;
	$out->{data}            = "Curse cast.";
	$out->{member_curse_id} = $mc->member_curse_id();
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
