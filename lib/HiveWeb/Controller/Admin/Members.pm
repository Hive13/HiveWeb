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
	my $member_attrs = {};

	if ($order ne 'accesses' && $order ne 'last_access_time')
		{
		my $sorder .= "$order $dir";
		$member_attrs->{order_by} = $sorder;
		}

	my @members = $c->model('DB::Member')->search({}, $member_attrs);
	my @omembers;
	foreach my $member (@members)
		{
		my %m = $member->get_columns();
		$m{accesses} = $member->search_related('access_logs')->count();
		my $lat = $member
			->search_related('access_logs', { granted => 1 }, { order_by => { -desc => [ 'access_time' ] } })
			->first();
		if (defined($lat))
			{
			$m{last_access_time} = $lat->access_time();
			}
		push (@omembers, \%m);
		}
	my @groups  = $c->model('DB::MGroup')->search({});

	if ($order eq 'accesses')
		{
		if ($dir eq 'ASC')
			{
			@omembers = sort { $a->{accesses} <=> $b->{accesses} } @omembers;
			}
		else
			{
			@omembers = sort { $b->{accesses} <=> $a->{accesses} } @omembers;
			}
		}
	elsif ($order eq 'last_access_time')
		{
		if ($dir eq 'ASC')
			{
			@omembers = sort
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
				@omembers;
			}
		else
			{
			@omembers = sort
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
				@omembers;
			}
		}

	$c->stash()->{groups}   = \@groups;
	$c->stash()->{members}  = \@omembers;
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
