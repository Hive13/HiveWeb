package HiveWeb::Controller::API::Admin::Curses;
use Moose;
use namespace::autoclean;

use Try::Tiny;

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

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $member_id = $in->{member_id};
	my $mgroup_id = $in->{mgroup_id};

	my $members;

	# Wonder if Perl has an XOR...
	if ((!$member_id && !$mgroup_id) || ($member_id && $mgroup_id))
		{
		$out->{response} = \0;
		$out->{data}     = "You must specify either a member or a group.";
		return;
		}

	if ($member_id)
		{
		my $member = $c->model('DB::Member')->find({ member_id => $member_id });
		if (!defined($member))
			{
			$out->{response} = \0;
			$out->{data}     = "Cannot find member " . $member_id;
			return;
			}
		$members = [ $member ];
		}
	else
		{
		my @members;
		my $mgroup = $c->model('DB::MGroup')->find({ mgroup_id => $mgroup_id });
		if (!defined($mgroup))
			{
			$out->{response} = \0;
			$out->{data}     = "Cannot find group " . $mgroup_id;
			return;
			}
		@members = $mgroup->member_mgroups()->search_related('member', {})->all();
		$members = \@members;
		}
	my $curse = $c->model('DB::Curse')->find({ curse_id => $in->{curse_id} });
	if (!defined($curse))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find curse " . $in->{curse_id};
		return;
		}

	$out->{response} = \1;
	$out->{data}     = "Curse cast.";
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $member (@$members)
				{
				my $mc = $c->model('DB::MemberCurse')->find(
					{
					member_id => $member->member_id(),
					curse_id  => $in->{curse_id},
					issued_at => { '<=' => \'now()' },
					lifted_at => [ { '>=' => \'now()' }, undef ],
					});

				if ($mc)
					{
					$out->{data} =  "A member already has that curse active.  Can't handle this yet.";
					die;
					}

				$mc = $c->model('DB::MemberCurse')->create(
					{
					member_id         => $member->member_id(),
					curse_id          => $in->{curse_id},
					issuing_member_id => $c->user()->member_id(),
					issuing_notes     => $in->{notes},
					}) || die $!;
				}
			});
		}
	catch
		{
		$out->{data} = Data::Dumper::Dumper($_)
			if ($out->{data} eq 'Curse cast.');
		$out->{response} = \0;
		}
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
