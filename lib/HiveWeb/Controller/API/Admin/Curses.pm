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

sub edit :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $in           = $c->stash()->{in};
	my $out          = $c->stash()->{out};
	$out->{response} = \0;

	my $curse;

	if ($in->{curse_id})
		{
		$curse = $c->model('DB::Curse')->find($in->{curse_id});
		if (!$curse)
			{
			$out->{data} = "Could not locate curse \"$in->{curse_id}\".";
			return;
			}
		}
	elsif (!$in->{name})
		{
		$out->{data} = 'You must provide a curse name.';
		return;
		}

	if (my $other_curse = $c->model('DB::Curse')->find({ name => $in->{name} }))
		{
		if (!$curse || $curse->curse_id ne $other_curse->curse_id())
			{
			$out->{data} = 'That curse name already exists.';
			return;
			}
		}

	if (!$curse)
		{
		$curse = $c->model('DB::Curse')->create($in);
		if (!$curse)
			{
			$out->{data} = 'Could not create curse.';
			return;
			}
		}
	elsif (!$curse->update($in))
		{
		$out->{data} = 'Could not update curse.';
		return;
		}

	$out->{response} = \1;
	$out->{curse}    = $curse;
	}

sub cast :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $member_id = $in->{member_id};
	my $mgroup_id = $in->{mgroup_id};
	my $existing  = $in->{existing};

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
		$existing ||= 'die';
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
		$existing ||= 'stack';
		}
	my $curse = $c->model('DB::Curse')->find({ curse_id => $in->{curse_id} });
	if (!defined($curse))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find curse " . $in->{curse_id};
		return;
		}

	$existing = lc($existing);

	if ($existing ne 'die' && $existing ne 'stack' && $existing ne 'replace')
		{
		$out->{response} = \0;
		$out->{data}     = "Invalid existing curse action $existing.";
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
				my $emc = $c->model('DB::MemberCurse')->find(
					{
					member_id => $member->member_id(),
					curse_id  => $in->{curse_id},
					issued_at => { '<=' => \'now()' },
					lifted_at => [ { '>=' => \'now()' }, undef ],
					});
				my $mc = $c->model('DB::MemberCurse')->create(
					{
					member_id         => $member->member_id(),
					curse_id          => $in->{curse_id},
					issuing_member_id => $c->user()->member_id(),
					issuing_notes     => $in->{notes},
					}) || die $!;

				if ($emc)
					{
					if ($existing eq 'die')
						{
						$out->{data} = "A member already has that curse active, and you elected to die on existing curses.  No one has been cursed.";
						die;
						}
					elsif ($existing eq 'replace')
						{
						$emc->update(
							{
							lifted_at         => \'now()',
							lifting_member_id => $c->user()->member_id(),
							lifting_notes     => 'Replaced by curse ' . $mc->member_curse_id(),
							});
						}
					}
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
