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

=encoding utf8

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
