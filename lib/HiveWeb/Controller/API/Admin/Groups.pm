package HiveWeb::Controller::API::Admin::Groups;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub info :Local :Args(1)
	{
	my ($self, $c, $group_id) = @_;

	my $out   = $c->stash()->{out};
	my $group = $c->model('DB::MGroup')->find($group_id, { prefetch => 'member_mgroups' });

	if (!defined($group))
		{
		$out->{response} = \0;
		$out->{data}     = "Cannot find group";
		return;
		}

	$out->{group}    = $group;
	$out->{response} = \1;
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in    = $c->stash()->{in};
	my $out   = $c->stash()->{out};
	my $order = $in->{order} || 'name';
	my $dir   = uc($in->{dir} || 'ASC');

	$c->session()->{group_table} //= {};
	my $group_table = $c->session()->{group_table};
	$group_table->{page}     = int($in->{page}) || 1;
	$group_table->{per_page} = int($in->{per_page}) || 10;

	$dir = 'ASC'
		if ($dir ne 'ASC' && $dir ne 'DESC');

	my $count_query = $c->model('DB::MemberMGroup')->search(
		{
		mgroup_id => { -ident => 'me.mgroup_id' },
		},
		{
		alias => 'gm_count',
		})->count_rs()->as_query();

	my $group_attrs =
		{
		prefetch  => 'member_mgroups',
		'+select' => $count_query,
		'+as'     => 'mcount',
		};

	my $sorder = "$order $dir";
	$group_attrs->{order_by} = $sorder;

	my @members   = $c->model('DB::Member')->search({});
	my $groups_rs = $c->model('DB::MGroup')->search({}, $group_attrs);
	my $count     = $groups_rs->count();
	my @groups    = $groups_rs->search({},
		{
		rows => $group_table->{per_page},
		page => $group_table->{page},
		});

	$out->{groups}   = \@groups;
	$out->{members}  = \@members;
	$out->{count}    = $count;
	$out->{page}     = $group_table->{page};
	$out->{per_page} = $group_table->{per_page};
	$out->{response} = \1;
	}

sub edit :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in        = $c->stash()->{in};
	my $out       = $c->stash()->{out};
	my $mgroup_id = $in->{mgroup_id};
	my $name      = $in->{name};
	my $mgroup;

	$out->{response} = \0;

	if ($mgroup_id)
		{
		$mgroup = $c->model('DB::MGroup')->find({ mgroup_id => $mgroup_id });
		if (!defined($mgroup))
			{
			$out->{data} = 'Cannot find group';
			return;
			}
		}
	if (!$name && !$mgroup)
		{
		$out->{data} = 'You must specify a group to edit or a name to create.';
		return;
		}
	if ($name)
		{
		my $other_group = $c->model('DB::MGroup')->find({ name => $name });
		if ($other_group && (!$mgroup || $mgroup->mgroup_id() eq $other_group->mgroup_id()))
			{
			$out->{data} = 'That group name already exists.';
			return;
			}
		}

	my %new_members = map { $_ => 1; } @{$in->{members}};
	my @members     = $c->model('DB::Member')->all();
	try
		{
		$c->model('DB')->txn_do(sub
			{
			if (!$mgroup)
				{
				$mgroup = $c->model('DB::MGroup')->create({ name => $name }) || die $!;
				}
			elsif ($name)
				{
				$mgroup->update({ name => $name });
				}

			foreach my $member (@members)
				{
				my $member_id = $member->member_id();
				if ($new_members{$member_id} && !$member->find_related('member_mgroups', { mgroup_id => $mgroup_id }))
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'add_group',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Added group ' . $mgroup_id,
						});
					$member->create_related('member_mgroups', { mgroup_id => $mgroup_id });
					}
				my $mg;
				if (!$new_members{$member_id} && ($mg = $member->find_related('member_mgroups', { mgroup_id => $mgroup_id })))
					{
					$member->create_related('changed_audits',
						{
						change_type        => 'remove_group',
						changing_member_id => $c->user()->member_id(),
						notes              => 'Removed group ' . $mgroup_id,
						});
					$mg->delete();
					}
				}
			$out->{response} = \1;
			$out->{data}     = 'Group has been updated.';
			});
		}
	catch
		{
		$out->{data} = "Could not update group.";
		};
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
