package HiveWeb::Controller::API::Admin::Members;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use DateTime;
use Image::Magick;

BEGIN { extends 'Catalyst::Controller'; }

sub profile :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $in         = $c->stash()->{in};
	my $out        = $c->stash()->{out};
	my $member_id  = $in->{member_id};

	$member_id ||= $c->user()->member_id();

	my $member = $c->model('DB::Member')->find($member_id);
	if (!$member)
		{
		$out->{data} = 'Invalid Member ID';
		return;
		}

	$out->{member}   = $member;
	$out->{response} = \1;
	}

sub info :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $member_id = $c->stash()->{in}->{member_id};

	if (!$member_id)
		{
		$out->{data} = 'You must specify a member ID.';
		return;
		}

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
		$out->{data} = "Cannot find member";
		return;
		}

	$out->{slots}    = [ $member->list_slots() ];
	$out->{badges}   = [ $member->badges() ];
	$out->{member}   = $member;
	$out->{linked}   = [ $member->linked_members() ];
	$out->{link}     = $member->link()
		if ($member->link());
	$out->{response} = \1;
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
		$out->{data} = "Cannot find member";
		return;
		}

	if (!$password)
		{
		$out->{data} = 'Blank or invalid password supplied.';
		return;
		}

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$member->set_password($password);
			$out->{data}     = "Member password has been updated.";
			$out->{response} = \1;
			});
		}
	catch
		{
		$out->{data} = 'Could not change password.';
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
		$out->{data} = "Cannot find member";
		return;
		}
	my %new_groups   = map { $_ => 1; } @{$in->{groups}};
	my @groups       = $c->model('DB::MGroup')->all();
	try
		{
		$c->model('DB')->txn_do(sub
			{
			if (exists($in->{badges}))
				{
				my %current_badges = map { $_->badge_id() => $_->badge_number() } $member->badges();
				my @new_badges;
				BADGE: foreach my $badge (@{ $in->{badges} })
					{
					if ($badge->{id})
						{
						delete($current_badges{$badge->{id}});
						}
					else
						{
						# Filter out deleting and re-adding the same badge number
						foreach my $id (keys(%current_badges))
							{
							if ($badge->{val} == $current_badges{$id})
								{
								delete($current_badges{$id});
								next BADGE;
								}
							}
						push(@new_badges, $badge->{val});
						}
					}
				foreach my $badge_id (keys(%current_badges))
					{
					my $badge = $c->model('DB::Badge')->find($badge_id);
					die
						if (!defined($badge));
					$badge->delete();
					}
				foreach my $badge_number (@new_badges)
					{
					my $badge = $member->create_related('badges', { badge_number => $badge_number });
					}
				}
			if (exists($in->{links}))
				{
				my %current_links = map { $_->member_id() => $_ } $member->linked_members();
				foreach my $linked_id (@{ $in->{links} })
					{
					die 'Cannot link to self'
						if ($linked_id eq $member_id);
					if ($current_links{$linked_id})
						{
						delete($current_links{$linked_id});
						}
					else
						{
						my $new_link = $c->model('DB::Member')->find($linked_id) || die "Invalid Member ID $linked_id";
						$new_link->update({ linked_member_id => $member_id });
						}
					}
				foreach my $linked_member_id (keys(%current_links))
					{
					$current_links{$linked_member_id}->update({ linked_member_id => undef });
					}
				}
			$member->update(
				{
				(exists($in->{member_image_id}) ? (member_image_id => $in->{member_image_id}) : ()),
				(exists($in->{paypal_email})    ? (paypal_email    => $in->{paypal_email}) : ()),
				(exists($in->{vend_credits})    ? (vend_credits    => $in->{vend_credits}) : ()),
				});

			foreach my $group (@groups)
				{
				my $group_id = $group->mgroup_id();
				$member->mod_group(
					{
					group_id => $group_id,
					(($new_groups{$group_id}) ? () : (del => 1)),
					});
				}
			$out->{response} = \1;
			$out->{data}     = 'Member profile has been updated.';
			});
		}
	catch
		{
		$out->{data} = 'Could not update member profile: ' . $_;
		};
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
		prefetch  => 'member_mgroups',
		'+select' => [ { '' => $count_query, -as => 'accesses' }, { '' => $last_query, -as => 'last_access_time' }, { '' => $sum_query, -as => 'access_total' } ],
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

	if (defined(my $linked = $in->{filters}->{linked}))
		{
		my $main_query = $c->model('DB::Member')->search({ linked_member_id => { '-ident' => 'me.member_id' } }, { alias => 'links' })->count_rs()->as_query();
		if ($linked eq 'sub')
			{
			$filters->{linked_member_id} = { '!=' => undef };
			}
		elsif ($linked eq 'main')
			{
			$filters->{$$main_query->[0]} = { '>=' => 1 };
			}
		elsif ($linked eq 'no')
			{
			$filters->{linked_member_id} = undef;
			$filters->{$$main_query->[0]} = 0;
			}
		elsif ($linked eq 'yes')
			{
			$filters->{'-or'} =
				[
				{ linked_member_id  => { '!=' => undef} },
				{ $$main_query->[0] => { '>=' => 1} },
				];
			}
		}

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
				$out->{data} = 'Unknown PayPal filter type ' . $type;
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
			$out->{data} = 'Unknown group filter type ' . $type;
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
			$out->{data} = "Unknown storage filter type '$type'.";
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
			elsif ($name =~ s/^tel://i)
				{
				push(@$names, \[ 'CAST(phone AS TEXT) like ?', '%' . $name . '%' ]);
				}
			elsif ($name =~ s/^badge://i)
				{
				my $search = \[ 'CAST(badge_number AS TEXT) like ?', '%' . $name . '%' ];
				my $badge = $c->model('DB::Badge')->search($search, { alias => 'badges' })->get_column('badges.member_id')->as_query();
				push(@$names, { member_id => { -in => $badge } });
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
	my @groups            = $c->model('DB::MGroup')->search({}, { prefetch => 'member_mgroups' });

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

	my @members    = $c->model('DB::Member')->search(
		{
		-and => $names,
		},
		{
		select       => ['member_id', 'fname', 'lname'],
		rows         => 10,
		page         => $page,
		result_class => 'DBIx::Class::ResultClass::HashRefInflator',
		order_by     => $order,
		});

	$out->{members}  = \@members;
	$out->{count}    = scalar(@members);
	$out->{page}     = $page;
	$out->{per_page} = 10;
	$out->{response} = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
