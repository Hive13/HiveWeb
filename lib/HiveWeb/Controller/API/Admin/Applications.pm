package HiveWeb::Controller::API::Admin::Applications;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private
	{
	my ($self, $c)   = @_;
	my $in           = $c->stash()->{in};
	my $out          = $c->stash()->{out};

	return 1
		if (!exists($in->{application_id}));

	my $application = $c->model('DB::Application')->find($in->{application_id});

	if (!$application)
		{
		$out->{data} = 'Cannot find application.';
		return;
		}

	$c->stash({ application => $application });
	}

sub finalize :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	my $application  = $c->stash()->{application};
	my $result       = $in->{result};
	my $member       = $application->member();

	if ($application->decided_at())
		{
		$out->{data} = 'This application is already finalized.';
		return;
		}

	if (!$result)
		{
		$out->{data} = 'You must specify a final action.';
		return;
		}
	if ($result eq 'accepted')
		{
		if (!$member->member_image_id())
			{
			$out->{data} = 'This member does not have an image attached.';
			return;
			}
		if (!$application->form_id())
			{
			$out->{data} = 'This application does not have a signed form attached.';
			return;
			}
		}

	$out->{response} = \1;

	try
		{
		$c->model('DB')->txn_do(sub
			{
			$application->update(
				{
				decided_at   => \'NOW()',
				final_result => $result,
				}) || die $!;
			if ($in->{actions} && ref($in->{actions}) eq 'ARRAY')
				{
				foreach my $action (@{$in->{actions}})
					{
					$action = lc($action);
					if ($action eq 'remove_from_group')
						{
						$member->mod_group({ group => \'pending_applications', del => 1 });
						}
					elsif ($action eq 'add_to_pending_payments')
						{
						$member->mod_group({ group => \'pending_payments' });
						}
					elsif ($action eq 'add_soda_credit')
						{
						$member->add_vend_credits(1);
						}
					elsif ($action eq 'add_badges')
						{
						foreach my $badge (@{ $in->{badges} })
							{
							$badge = $member->create_related('badges', { badge_number => $badge->{val} });
							}
						}
					}
				}
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not finalize application: ' . $_;
		};
	}

sub pending :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};

	my @pending_applications = $c->model('DB::Application')->search(
		{
		decided_at => undef,
		},
		{
		order_by => { -asc => 'me.updated_at' },
		prefetch => { member => 'member_mgroups' },
		})->all();

	$out->{response} = \1;
	$out->{app_info} = \@pending_applications;
	}

sub attach_picture_to_member :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	my $application  = $c->stash()->{application};

	if (!$application->picture_id())
		{
		$out->{data} = 'This application does not have a picture attached.';
		return;
		}

	try
		{
		$application->link_picture();
		$out->{response} = \1;
		$out->{data}     = 'Picture linked to member account.';
		}
	catch
		{
		$out->{data} = 'Could not link picture: ' . $_;
		};
	}

__PACKAGE__->meta->make_immutable;

1;
