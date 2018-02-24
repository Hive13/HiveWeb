package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use DateTime;

BEGIN { extends 'Catalyst::Controller'; }

sub info :Local :Args(1)
	{
	my ($self, $c, $member_id) = @_;

	my $out = $c->stash()->{out};

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

	my $member = $c->model('DB::Member')->find(
		{
		member_id => $member_id,
		},
		{
		'+select' => [ $count_query, $last_query ],
		'+as'     => [ 'accesses', 'last_access_time' ],
		});
	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member";
		return;
		}

	my @badges = $member->badges();
	my @obadges;
	foreach my $badge (@badges)
		{
		push(@obadges,
			{
			badge_id     => $badge->badge_id(),
			badge_number => $badge->badge_number()
			});
		}
	my @slots = $member->list_slots();

	$out->{slots}    = \@slots;
	$out->{badges}   = \@obadges;
	$out->{member}   = $member;
	$out->{response} = \1;
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

sub photo :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $member_id = $in->{member_id};
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member";
		return;
		}

	if ($member->member_image_id())
		{
		$out->{response} = \0;
		$out->{data}     = "This member already has an image.  Please remove the old one.";
		return;
		}

	my $image = $c->request()->upload('photo');
	if (!$image)
		{
		$out->{response} = \0;
		$out->{data}     = 'Cannot find image data.';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $db_image = $c->model('DB::Image')->create(
				{
				image        => $image->slurp(),
				content_type => $image->type(),
				}) || die $!;
			my $image_id = $db_image->image_id();
			$member->create_related('changed_audits',
				{
				change_type        => 'image',
				changing_member_id => $c->user()->member_id(),
				notes              => 'Attached image ' . $image_id,
				}) || die $!;
			$member->update({ member_image_id => $image_id }) || die $!;
			$out->{image_id} = $image_id;
			});
		}
	catch
		{
		delete($out->{image_id});
		$out->{response} = \0;
		$out->{data}     = 'Could not update member profile: ' . $_;
		};
	$out->{response} = \1;
	$out->{data}     = 'Member picture updated.';
	}

sub remove_photo :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $member_id = $in->{member_id};
	my $member    = $c->model('DB::Member')->find({ member_id => $member_id });

	if (!defined($member))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find member";
		return;
		}

	if (!$member->member_image_id())
		{
		$out->{response} = \0;
		$out->{data}     = "This member does not have an image.";
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->create_related('changed_audits',
				{
				change_type        => 'image',
				changing_member_id => $c->user()->member_id(),
				notes              => 'Detached image ' . $member->member_image_id(),
				}) || die $!;
			$member->update({ member_image_id => undef }) || die $!;
			});
		}
	catch
		{
		delete($out->{image_id});
		$out->{response} = \0;
		$out->{data}     = 'Could not update member profile: ' . $_;
		};
	$out->{response} = \1;
	$out->{data}     = 'Member picture removed.';
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $order   = lc($in->{order} || 'lname');
	my $dir     = lc($in->{dir} || 'asc');
	my $dtp     = $c->model('DB')->storage()->datetime_parser();
	my $filters = {};

	$c->session()->{member_table} //= {};
	my $member_table = $c->session()->{member_table};
	$member_table->{page}     = int($in->{page}) || 1;
	$member_table->{per_page} = int($in->{per_page}) || 10;

	$dir = 'asc'
		if ($dir ne 'asc' && $dir ne 'desc');

	my $count_query = $c->model('DB::AccessLog')->search(
		{
		granted   => 't',
		member_id => \'= me.member_id',
		},
		{
		alias => 'al_count',
		})->count_rs()->as_query();
	$$count_query->[0] .= ' AS accesses';

	my $sum_query = $c->model('DB::AccessLog')->search(
		{
		granted   => 't',
		member_id => \'= me.member_id',
		},
		{
		alias  => 'access_total',
		select => \'count(access_total.*) + coalesce(me.door_count, 0)',
		as     => 'atot'
		})->get_column('atot')->as_query();
	$$sum_query->[0] .= ' AS access_total';

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
	$$last_query->[0] .= ' AS last_access_time';

	# Cannot prefetch 'member_mgroups' as it conflicts with the 'AS X' hack on the subqueries.
	my $member_attrs =
		{
		'+select' => [ $count_query, $last_query, $sum_query ],
		'+as'     => [ 'accesses', 'last_access_time', 'access_total' ],
		};

	if ($order eq 'last_access_time')
		{
		if ($dir eq 'desc')
			{
			$member_attrs->{order_by} = \'last_access_time DESC NULLS LAST';
			}
		else
			{
			$member_attrs->{order_by} = \'last_access_time ASC NULLS FIRST';
			}
		}
	elsif ($order eq 'accesses')
		{
		$member_attrs->{order_by} = { "-$dir" => 'access_total' };
		}
	else
		{
		$member_attrs->{order_by} = { "-$dir" => $order };
		}

	$filters->{member_image_id} = ($in->{filters}->{photo} ? { '!=' => undef } : undef)
		if (defined($in->{filters}->{photo}));

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
			$member_attrs->{join} = 'member_mgroups';
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
	if (defined(my $value = $in->{filters}->{storage_value}) && defined(my $type = $in->{filters}->{storage_type}))
		{
		$value = int($value) || 0;
		$type  = lc($type);
		my $query;

		if ($type eq 'l')
			{
			$query = { '<' => $value};
			}
		elsif ($type eq 'le')
			{
			$query = { '<=' => $value};
			}
		elsif ($type eq 'e')
			{
			$query = $value;
			}
		elsif ($type eq 'ge')
			{
			$query = { '>=' => $value};
			}
		elsif ($type eq 'g')
			{
			$query = { '>' => $value};
			}
		else
			{
			$out->{error}    = "Unknown storage filter type '$type'.";
			$out->{response} = \0;
			return;
			}
		my $ss = $c->model('DB::StorageSlot')->search({ member_id => { '-ident' => 'me.member_id' } }, { alias => 'slots' })->count_rs()->as_query();
		$filters->{$$ss->[0]} = $query;
		}

	if (my $search = $in->{search})
		{
		my @names = split(/\s+/, $search);

		$filters->{'-and'} = []
			if (!exists($filters->{'-and'}));
		my $names = $filters->{'-and'};

		foreach my $name (@names)
			{
			if ($name =~ s/^email://i)
				{
				push(@$names, { email => { ilike => '%' . $name . '%' } });
				}
			elsif ($name =~ s/^handle://i)
				{
				push(@$names, { handle => { ilike => '%' . $name . '%' } });
				}
			elsif ($name =~ s/^paypal://i)
				{
				push(@$names, { paypal_email => { ilike => '%' . $name . '%' } });
				}
			elsif ($name =~ s/^fname://i)
				{
				push(@$names, { fname => { ilike => '%' . $name . '%' } });
				}
			elsif ($name =~ s/^lname://i)
				{
				push(@$names, { lname => { ilike => '%' . $name . '%' } });
				}
			elsif ($name =~ s/^name://i)
				{
				push(@$names,
					{
					-or =>
						{
						fname => { ilike => '%' . $name . '%' },
						lname => { ilike => '%' . $name . '%' },
						}
					});
				}
			else
				{
				push (@$names,
					{
					-or =>
						{
						fname        => { ilike => '%' . $name . '%' },
						lname        => { ilike => '%' . $name . '%' },
						handle       => { ilike => '%' . $name . '%' },
						email        => { ilike => '%' . $name . '%' },
						paypal_email => { ilike => '%' . $name . '%' },
						}
					});
				}
			}
		}

	my $tot_count = $c->model('DB::Member')->search({})->count();
	my $count     = $c->model('DB::Member')->search($filters, $member_attrs)->count();

	$member_table->{page} = int(($count + $member_table->{per_page} - 1) / $member_table->{per_page})
		if (($member_table->{per_page} * $member_table->{page}) > $count);

	$member_attrs->{rows} = $member_table->{per_page};
	$member_attrs->{page} = $member_table->{page};
	my @members           = $c->model('DB::Member')->search($filters, $member_attrs);
	my @groups            = $c->model('DB::MGroup')->search({});

	$out->{groups}   = \@groups;
	$out->{members}  = \@members;
	$out->{count}    = $count;
	$out->{total}    = $tot_count;
	$out->{page}     = $member_table->{page};
	$out->{per_page} = $member_table->{per_page};
	$out->{response} = \1;
	}

sub search :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in    = $c->stash()->{in};
	my $out   = $c->stash()->{out};
	my $order = [ 'lname', 'fname' ];
	my $page  = $in->{page} || 1;
	my @names = split(/\s+/, $in->{name});
	my $names = [];

	foreach my $name (@names)
		{
		push (@$names,
			{
			-or =>
				{
				fname => { ilike => '%' . $name . '%' },
				lname => { ilike => '%' . $name . '%' },
				}
			});
		}

	my $members_rs = $c->model('DB::Member')->search(
		{
		-and => $names,
		},
		{
		order_by => $order
		});
	my $count      = $members_rs->count();
	my @members    = $members_rs->search({},
		{
		rows => 10,
		page => $page,
		});

	$out->{members}  = \@members;
	$out->{count}    = $count;
	$out->{page}     = $page;
	$out->{per_page} = 10;
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
