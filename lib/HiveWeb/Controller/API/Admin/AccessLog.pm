package HiveWeb::Controller::API::Admin::AccessLog;
use Moose;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use DateTime;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in      = $c->stash()->{in};
	my $out     = $c->stash()->{out};
	my $order   = $in->{order} || 'access_time';
	my $dir     = uc($in->{dir} || 'DESC');
	my $dtp     = $c->model('DB')->storage()->datetime_parser();
	my $filters = {};

	$c->session()->{access_log_table} //= {};
	my $access_log_table = $c->session()->{access_log_table};
	$access_log_table->{page}     = int($in->{page}) || 1;
	$access_log_table->{per_page} = int($in->{per_page}) || 10;

	$dir = 'DESC'
		if ($dir ne 'ASC' && $dir ne 'DESC');

	my $member_attrs = {};

	my $sorder .= "$order $dir";
	$member_attrs->{order_by} = $sorder;

	$filters->{granted} = ($in->{filters}->{granted} ? 't' : 'f')
		if (defined($in->{filters}->{granted}));

	if (defined(my $list = $in->{filters}->{item_list}) && defined(my $type = $in->{filters}->{item_type}))
		{
		$list = [ $list ]
			if (ref($list) ne 'ARRAY');
		$type = lc($type);

		if ($type eq 'any')
			{
			$filters->{'item_id'} = $list;
			}
		elsif ($type eq 'not_any')
			{
			$filters->{'item_id'} = { -not_in => $list };
			}
		else
			{
			$out->{error}    = 'Unknown item filter type ' . $type;
			$out->{response} = \0;
			return;
			}
		}

	if (defined(my $search = $in->{search}))
		{
		my @names = split(/\s+/, $in->{search});
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

		my $member_id_query = $c->model('DB::Member')->search({ -and => $names })->get_column('me.member_id')->as_query();
		$filters->{member_id} = { -in => $member_id_query };
		}

	my $needed_members = {};
	my $access_log_rs  = $c->model('DB::AccessLog')->search($filters, $member_attrs);
	my $access_count   = $c->model('DB::AccessLog')->search({})->count();
	my $count          = $access_log_rs->count();
	my @accesses       = $access_log_rs->search({},
		{
		rows => $access_log_table->{per_page},
		page => $access_log_table->{page},
		});

	my $ao = [];

	foreach my $access (@accesses)
		{
		push(@$ao,
			{
			access_id   => $access->access_id(),
			access_time => $access->access_time(),
			member_id   => $access->member_id(),
			granted     => $access->granted() ? \1 : \0,
			badge       => $access->badge_id(),
			item_id     => $access->item_id(),
			});

		$needed_members->{$access->member_id()} = 1
			if ($access->member_id());
		}

	my @items = $c->model('DB::Item')->search({});
	my $item_hash = { map { $_->item_id() => $_ } @items };
	my @members = $c->model('DB::Member')->search({ member_id => [ keys %$needed_members ] });
	my $member_hash = { map { $_->member_id() => $_ } @members };

	$out->{accesses} = $ao;
	$out->{items}    = $item_hash;
	$out->{members}  = $member_hash;
	$out->{count}    = $count;
	$out->{total}    = $access_count;
	$out->{page}     = $access_log_table->{page};
	$out->{per_page} = $access_log_table->{per_page};
	$out->{response} = \1;
	}

sub recent :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $out        = $c->stash()->{out};

	my @accesses = $c->model('DB::AccessLog')->search({},
		{
		order_by => { -desc => 'me.access_time' },
		rows     => 10,
		prefetch => [ 'item', 'member' ],
		});
	$out->{accesses} = \@accesses;
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
