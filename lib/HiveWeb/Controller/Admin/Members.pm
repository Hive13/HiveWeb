package HiveWeb::Controller::Admin::Members;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my $self  = shift;
	my $c     = shift;

	$c->response()->redirect($c->uri_for('/admin/members/view'));
	}

sub view :Local
	{
	my $self  = shift;
	my $c     = shift;
	my $order = shift // 'lname';
	my $dir   = uc(shift // 'ASC');

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
		select => { to_char => [ { max => 'access_time' }, \"'MM/DD/YYYY HH12:MI:SS AM'" ] },
		alias  => 'al_time',
		}
	)->as_query();

	my $member_attrs =
		{
		'+select' => [ $count_query, $last_query ],
		'+as'     => [ 'accesses', 'last_access_time' ],
		};

	if ($order ne 'accesses' && $order ne 'last_access_time')
		{
		my $sorder .= "$order $dir";
		$member_attrs->{order_by} = $sorder;
		}

	my @members = $c->model('DB::Member')->search({}, $member_attrs);
	my @groups  = $c->model('DB::MGroup')->search({});

	if ($order eq 'accesses')
		{
		if ($dir eq 'ASC')
			{
			@members = sort { $a->{accesses} <=> $b->{accesses} } @members;
			}
		else
			{
			@members = sort { $b->{accesses} <=> $a->{accesses} } @members;
			}
		}
	elsif ($order eq 'last_access_time')
		{
		if ($dir eq 'ASC')
			{
			@members = sort
				{
				my $at = $a->{last_access_time};
				my $bt = $b->{last_access_time};
				if (!defined($at))
					{
					return -1
						if (defined($bt));
					return 0;
					}
				return 1
					if (!defined($bt));
				DateTime->compare($at, $bt);
				}
				@members;
			}
		else
			{
			@members = sort
				{
				my $at = $b->{last_access_time};
				my $bt = $a->{last_access_time};
				if (!defined($at))
					{
					return -1
						if (defined($bt));
					return 0;
					}
				return 1
					if (!defined($bt));
				DateTime->compare($at, $bt);
				}
				@members;
			}
		}

	$c->stash()->{groups}   = \@groups;
	$c->stash()->{members}  = \@members;
	$c->stash()->{order}    = $order;
	$c->stash()->{dir}      = $dir;
	$c->stash()->{template} = 'admin/members/index.tt';
	}

=encoding utf8

=head1 AUTHOR

Greg Arnold,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
