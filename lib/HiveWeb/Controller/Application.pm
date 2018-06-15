package HiveWeb::Controller::Application;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'application/new.tt';

	return
		if ($c->request()->method() eq 'GET');

	my $form = $c->request()->params();
	my $fail = {};
	my $application;

	foreach my $key (keys(%$form))
		{
		delete ($form->{$key})
			if ($form->{$key} eq '');
		}

	if ($form->{zip})
		{
		my $zip = $form->{zip};
		$zip =~ s/[^0-9]//g;
		$form->{zip} = $zip;
		$fail->{zip} = 'Please provide your 5-digit ZIP code with or without your plus 4.'
			if (length($zip) != 5 && length($zip) != 9);
		}
	else
		{
		$fail->{zip} = 'You must provide you ZIP code.';
		}

	$fail->{address1} = 'You must provide your mailing address.'
		if (!$form->{address1});
	$fail->{city} = 'You must provide your mailing city.'
		if (!$form->{city});
	if ($form->{state})
		{
		$form->{state} =~ tr/a-z/A-Z/;
		$fail->{state} = 'Please provide the two-letter state abbreviation for your mailing state.'
			if ($form->{state} !~ /[A-Z]{2}/);
		}
	else
		{
		$fail->{state} = 'You must provide your mailing state.';
		}

	if (scalar(%$fail))
		{
		$c->stash(
			{
			message     => $fail,
			application => $form
			});
		return;
		}
	try
		{
		$form->{member_id} = $c->user()->member_id();
		$c->model('DB')->schema()->txn_do(sub
			{
			my $group = 'pending_applications';
			$application = $c->model('DB::Application')->create($form) || die $!;
			my $mgroup = $c->model('DB::MGroup')->find({ name => $group }) || die 'Unable to locate group ' . $group;
			$mgroup->find_or_create_related('member_mgroups', { member_id => $c->user()->member_id() }) || die 'Unable to add user to group.';
			});

		$c->stash(
			{
			template    => 'application/complete.tt',
			application => $application,
			});
		}
	catch
		{
		$c->stash(
			{
			message => { error => $_ },
			vals    => $form
			});
		};
	}

__PACKAGE__->meta->make_immutable;

1;
