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

	$out->{response} = \1;

	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $member = $application->member();
			$c->model('DB::Action')->create(
				{
				queuing_member_id => $c->user()->member_id(),
				action_type       => 'application.finalize',
				row_id            => $application->application_id(),
				}) || die 'Could not queue notification: ' . $!;
			$member->create_related('changed_audits',
				{
				change_type        => 'finalize_application',
				notes              => 'Finalized Application ID ' . $application->application_id(),
				changing_member_id => $c->user()->member_id(),
				}) || die 'Could not audit finalization: ' . $!;
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
						my $group    = $c->model('DB::MGroup')->find({ name => 'pending_applications' }) || die;
						my $group_id = $group->mgroup_id();
						$member->find_related('member_mgroups', { mgroup_id => $group_id })->delete();
						$member->create_related('changed_audits',
							{
							change_type        => 'remove_group',
							changing_member_id => $c->user()->member_id(),
							notes              => 'Removed group ' . $group_id,
							});
						}
					elsif ($action eq 'add_to_members')
						{
						my $group    = $c->model('DB::MGroup')->find({ name => 'members' }) || die;
						my $group_id = $group->mgroup_id();
						$member->create_related('changed_audits',
							{
							change_type        => 'add_group',
							changing_member_id => $c->user()->member_id(),
							notes              => 'Added group ' . $group_id
							});
						$member->find_or_create_related('member_mgroups', { mgroup_id => $group_id }) || die;
						}
					elsif ($action eq 'add_soda_credit')
						{
						$member->create_related('changed_audits',
							{
							change_type        => 'add_credits',
							changing_member_id => $c->user()->member_id(),
							notes              => 'Added 1 credit',
							});
						$member->add_vend_credits(1);
						}
					elsif ($action eq 'add_badges')
						{
						foreach my $badge (@{ $in->{badges} })
							{
							my $badge_number = $badge->{val};
							$member->create_related('changed_audits',
								{
								change_type        => 'add_badge',
								notes              => 'Badge number ' . $badge_number,
								changing_member_id => $c->user()->member_id(),
								});
							$badge = $member->create_related('badges', { badge_number => $badge_number });
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

	$out->{response} = \1;
	$out->{data}     = 'Picture linked to member account.';
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $member = $application->member();
			$member->create_related('changed_audits',
				{
				change_type        => 'attach_photo_from_application',
				notes              => 'Attached image ID ' . $application->picture_id(),
				changing_member_id => $c->user()->member_id(),
				});
			$member->update({ member_image_id => $application->picture_id() });
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not link picture: ' . $_;
		};
	}

__PACKAGE__->meta->make_immutable;

1;
