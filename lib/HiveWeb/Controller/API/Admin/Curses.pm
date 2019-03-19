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
	my $order   = lc($in->{order} || 'priority');
	my $dir     = lc($in->{dir} || 'asc');
	my $filters = {};
	my $attrs   = {};

	$c->session()->{curse_table} //= {};
	my $curse_table = $c->session()->{curse_table};
	$curse_table->{page}     = int($in->{page}) || 1;
	$curse_table->{per_page} = int($in->{per_page}) || 10;

	$dir = 'asc'
		if ($dir ne 'asc' && $dir ne 'desc');
	$attrs->{order_by} = { "-$dir" => $order };

	$filters->{protect_group_cast} = ($in->{filters}->{group} ? 't' : 'f')
		if (defined($in->{filters}->{group}));
	$filters->{protect_user_cast} = ($in->{filters}->{indiv} ? 't' : 'f')
		if (defined($in->{filters}->{indiv}));
	$filters->{name} = [ '-and', map { { ilike => "%$_%" } } split(/\s+/, $in->{search}) ]
		if ($in->{search});

	my $tot_count = $c->model('DB::Curse')->search({})->count();
	my $count     = $c->model('DB::Curse')->search($filters, $attrs)->count();

	$curse_table->{page} = int(($count + $curse_table->{per_page} - 1) / $curse_table->{per_page})
		if (($curse_table->{per_page} * $curse_table->{page}) > $count);

	$attrs->{rows} = $curse_table->{per_page};
	$attrs->{page} = $curse_table->{page};
	my @curses     = $c->model('DB::Curse')->search($filters, $attrs);

	$out->{response} = \1;
	$out->{curses}   = \@curses;
	$out->{count}    = $count;
	$out->{total}    = $tot_count;
	$out->{page}     = $curse_table->{page};
	$out->{per_page} = $curse_table->{per_page};
	}

sub edit :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};

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
		$out->{data} = "You must specify either a member or a group.";
		return;
		}

	if ($member_id)
		{
		my $member = $c->model('DB::Member')->find({ member_id => $member_id });
		if (!defined($member))
			{
			$out->{data} = "Cannot find member " . $member_id;
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
			$out->{data} = "Cannot find group " . $mgroup_id;
			return;
			}
		@members = $mgroup->member_mgroups()->search_related('member', {})->all();
		$members = \@members;
		$existing ||= 'stack';
		}
	my $curse = $c->model('DB::Curse')->find({ curse_id => $in->{curse_id} });
	if (!defined($curse))
		{
		$out->{data} = "Cannot find curse " . $in->{curse_id};
		return;
		}

	$existing = lc($existing);

	if ($existing ne 'die' && $existing ne 'stack' && $existing ne 'replace')
		{
		$out->{data} = "Invalid existing curse action $existing.";
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

sub action_edit :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};

	if (my $curse_id = delete($in->{curse_id}))
		{
		my $curse = $c->model('DB::Curse')->find($curse_id);
		if (!$curse)
			{
			$out->{data} = "Could not find curse \"$curse_id\".";
			return;
			}
		my $action = $curse->create_related('curse_actions', $in) || die $!;
		$out->{response}  = \1;
		$out->{action_id} = $action->curse_action_id();
		return;
		}
	elsif (my $action_id = delete($in->{action_id}))
		{
		my $action = $c->model('DB::CurseAction')->find($action_id);
		if (!$action)
			{
			$out->{data} = "Could not find action \"$action_id\".";
			return;
			}
		$action->update($in) || die $!;
		$out->{response} = \1;
		return;
		}
	else
		{
		$out->{data} = 'You must specify a curse to add an action to or an action to edit.';
		}
	}

sub action_delete :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};

	my $action_id = delete($in->{action_id});
	my $action = $c->model('DB::CurseAction')->find($action_id);
	if (!$action)
		{
		$out->{data} = "Could not find action \"$action_id\".";
		return;
		}
	$action->delete() || die $!;
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
