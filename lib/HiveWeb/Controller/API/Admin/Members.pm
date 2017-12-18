package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use DateTime;

BEGIN { extends 'Catalyst::Controller'; }

sub lock :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};
	my $lock      = $c->stash()->{in}->{lock} // 1;
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member " . $member_id;
		return;
		}

	$out->{response} = \1;
	$out->{data}     = 'Member ' . ($lock ? 'locked out' : 'unlocked');
	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => $lock ? 'lock' : 'unlock',
				changing_member_id => $c->user()->member_id(),
				});
			$member->is_lockedout($lock);
			$member->update();
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update member.';
		};
	}

sub info :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	my $member = $c->model('DB::Member')->find({ member_id => $member_id });
	if (!defined($member))
		{
		$c->stash()->{out}->{response} = JSON->false();
		$c->stash()->{out}->{data}     = "Cannot find member";
		return;
		}

	my @badges = $member->badges();
	my @obadges;
	foreach my $badge (@badges)
		{
		push(@obadges, { $badge->get_inflated_columns() });
		}
	$c->stash()->{out}->{badges}   = \@obadges;
	$c->stash()->{out}->{member}   = $member;
	$c->stash()->{out}->{response} = \1;
	}

sub add_badge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $member_id    = $c->stash()->{in}->{member_id};
	my $badge_number = $c->stash()->{in}->{badge_number};
	my $member       = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find member';
		return;
		}
	if (!defined($badge_number))
		{
		$out->{response} = \0;
		$out->{data}     = 'No badge specified';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'add_badge',
				notes              => 'Badge number ' . $badge_number,
				changing_member_id => $c->user()->member_id(),
				});
			my $badge = $member->create_related('badges', { badge_number => $badge_number });
			$out->{badge_number} = $badge_number;
			$out->{badge_id}     = $badge->badge_id();
			$out->{response}     = \1;
			$out->{data}         = 'Badge created';
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update member.';
		};
	}

sub delete_badge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out          = $c->stash()->{out};
	my $member_id    = $c->stash()->{in}->{member_id};
	my $badge_ids    = $c->stash()->{in}->{badge_ids} // $c->stash()->{in}->{badge_id};
	my $member       = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find member';
		return;
		}
	if (!defined($badge_ids))
		{
		$out->{response} = \0;
		$out->{data}     = 'No badge specified';
		return;
		}

	$badge_ids = [ $badge_ids ]
		if (ref($badge_ids) ne 'ARRAY');

	$out->{response} = \1;
	$out->{data}     = "Badges deleted";
	try
		{
		$c->model('DB')->txn_do(sub
			{
			foreach my $badge_id (@$badge_ids)
				{
				my $badge = $c->model('DB::Badge')->find($badge_id);
				die
					if (!defined($badge));
				$member->create_related('changed_audits',
					{
					change_type        => 'delete_badge',
					notes              => 'Badge number ' . $badge->badge_number(),
					changing_member_id => $c->user()->member_id(),
					});
				$badge->delete();
				}
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = "One or more badges was invalid";
		};
	}

sub password :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};
	my $password  = $c->stash()->{in}->{password};
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = JSON->false();
		$out->{data}     = "Cannot find member";
		return;
		}

	if (!$password)
		{
		$out->{response} = \0;
		$out->{data}     = 'Blank or invalid password supplied.';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'change_password',
				changing_member_id => $c->user()->member_id(),
				});
			$member->set_password($password);
			$out->{data}     = "Member password has been updated.";
			$out->{response} = \1;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not change password.';
		};
	}

sub edit :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = JSON->false();
		$out->{data}     = "Cannot find member";
		return;
		}
	my %new_groups   = map { $_ => 1; } @{$in->{groups}};
	my @groups       = $c->model('DB::MGroup')->all();
	try
		{
		$c->model('DB')->txn_do(sub
			{
			if (exists($in->{paypal_email}))
				{
				my $paypal = $in->{paypal_email};
				if (defined($member->paypal_email()) != defined($paypal) || $member->paypal_email() ne $paypal)
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'change_paypal_email',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Set paypal e-mail to ' . ($paypal // '(null)'),
						});
					$member->update({ paypal_email => $paypal });
					}
				}
			if (exists($in->{vend_credits}))
				{
				my $vend_credits = int($in->{vend_credits});
				if ($member->vend_credits() != $vend_credits)
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'change_credits',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Set credits to ' . $vend_credits,
						});
					$member->update({ vend_credits => $vend_credits });
					}
				}

			foreach my $group (@groups)
				{
				my $group_id = $group->mgroup_id();
				if ($new_groups{$group_id} && !$member->find_related('member_mgroups', { mgroup_id => $group_id }))
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'add_group',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Added group ' . $group_id
						});
					$member->create_related('member_mgroups', { mgroup_id => $group_id });
					}
				my $mg;
				if (!$new_groups{$group_id} && ($mg = $member->find_related('member_mgroups', { mgroup_id => $group_id })))
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'remove_group',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Removed group ' . $group_id
						});
					$mg->delete();
					}
				}
			$out->{response} = \1;
			$out->{data}     = 'Member profile has been updated.';
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not update member profile.';
		};
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $order   = $in->{order} || 'lname';
	my $dir     = uc($in->{dir} || 'ASC');
	my $dtp     = $c->model('DB')->storage()->datetime_parser();
	my $filters = {};

	$dir = 'ASC'
		if ($dir ne 'ASC' && $dir ne 'DESC');

	my $count_query = $c->model('DB::AccessLog')->search(
		{
		granted   => 't',
		member_id => \'= me.member_id',
		},
		{
		alias => 'al_count',
		})->count_rs()->as_query();

	my $last_query = $c->model('DB::AccessLog')->search(
		{
		granted   => 't',
		member_id => \'= me.member_id',
		},
		{
		select => { max => 'access_time' },
		as     => [ 'last_access_time' ],
		alias  => 'al_time',
		}
	)->get_column('last_access_time')->as_query();

	my $member_attrs =
		{
		'+select' => [ $count_query, $last_query ],
		'+as'     => [ 'accesses', 'last_access_time' ],
		prefetch  => 'member_mgroups',
		};

	if ($order ne 'accesses' && $order ne 'last_access_time')
		{
		my $sorder .= "$order $dir";
		$member_attrs->{order_by} = $sorder;
		}

	$filters->{is_lockedout} = ($in->{filters}->{active} ? 0 : 1)
		if (defined($in->{filters}->{active}));

	if (defined(my $pp = $in->{filters}->{paypal}))
		{
		$pp = [ $pp ]
			if (ref($pp) ne 'ARRAY');

		my @pp_filters;
		foreach my $type (@$pp)
			{
			$type = lc($type);
			if ($type eq 'same')
				{
				push (@pp_filters, undef);
				}
			elsif ($type eq 'no')
				{
				push (@pp_filters, '');
				}
			elsif ($type eq 'diff')
				{
				push (@pp_filters,
					[ -and =>
						{ '!=' => undef },
						{ '!=' => '' },
					]);
				}
			else
				{
				$out->{error}    = 'Unknown PayPal filter type ' . $type;
				$out->{response} = \0;
				return;
				}
			}
		$filters->{paypal_email} = \@pp_filters;
		}

	if (defined(my $list = $in->{filters}->{group_list}) && defined(my $type = $in->{filters}->{group_type}))
		{
		$list = [ $list ]
			if (ref($list) ne 'ARRAY');
		$type = lc($type);

		if ($type eq 'all')
			{
			my $i;
			$member_attrs->{join} = [];
			my $g_where = [];
			for (my $i = 0; $i < scalar(@$list); $i++)
				{
				my $join_name = 'member_mgroups_' . ($i + 1);
				$join_name = 'member_mgroups'
					if (!$i);

				push(@{ $member_attrs->{join} }, 'member_mgroups');
				push(@$g_where, { ($join_name . '.mgroup_id') => $list->[$i] });
				}
			$filters->{'-and'} = $g_where;
			}
		elsif ($type eq 'any')
			{
			$filters->{'member_mgroups.mgroup_id'} = $list;
			}
		elsif ($type eq 'not_any')
			{
			my $i = 0;
			my $g_where = [];
			foreach my $group_id (@$list)
				{
				my $group_query = $c->model('DB::MemberMGroup')->search(
					{
					mgroup_id => $group_id,
					},
					{
					alias => 'mgroup' . $i++,
					})->get_column('member_id')->as_query();
				push(@$g_where, { 'me.member_id' => { -not_in => $group_query } });
				}
			$filters->{'-and'} = $g_where;
			}
		elsif ($type eq 'not_all')
			{
			# TODO: Insert brain.  Develop answer.
			}
		else
			{
			$out->{error}    = 'Unknown group filter type ' . $type;
			$out->{response} = \0;
			return;
			}
		}

	my @members = $c->model('DB::Member')->search($filters, $member_attrs);
	my @groups  = $c->model('DB::MGroup')->search({});

	if ($order eq 'accesses')
		{
		@members = sort { $a->get_column('accesses') - $b->get_column('accesses') } @members;
		@members = reverse(@members)
			if ($dir eq 'DESC');
		}
	elsif ($order eq 'last_access_time')
		{
		@members = sort
			{
			my $ad = $a->get_column('last_access_time');
			my $bd = $b->get_column('last_access_time');

			if (!defined($ad))
				{
				return -1
					if (defined($bd));
				return 0;
				}
			return 1
				if (!defined($bd));

			my $at = $dtp->parse_datetime($ad);
			my $bt = $dtp->parse_datetime($bd);
			DateTime->compare($at, $bt);
			}
			@members;
		@members = reverse(@members)
			if ($dir eq 'DESC');
		}

	$out->{groups}   = \@groups;
	$out->{members}  = \@members;
	$out->{response} = \1;
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
