package HiveWeb::Controller::API::Admin::Applications;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub pending :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	$out->{response} = \0;

	my @pending_applications = $c->model('DB::Application')->search(
		{
		decided_at => undef,
		},
		{
		order_by => { -asc => 'updated_at' },
		})->all();

	$out->{response} = \1;
	$out->{app_info} = \@pending_applications;
	}

sub attach_picture_to_member :Local :Args(0)
	{
	my ($self, $c)   = @_;
	my $out          = $c->stash()->{out};
	my $in           = $c->stash()->{in};
	$out->{response} = \0;

	my $application = $c->model('DB::Application')->find($in->{application_id});
	if (!$application)
		{
		$out->{response} = 'Invalid application ID';
		return;
		}
	if (!$application->picture_id())
		{
		$out->{response} = 'This application does not have a picture attached.';
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
