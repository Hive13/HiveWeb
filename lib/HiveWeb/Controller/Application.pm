package HiveWeb::Controller::Application;
use Moose;
use namespace::autoclean;

use Try::Tiny;
use PDF::API2;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path
	{
	my ($self, $c, $application_id) = @_;

	my $user = $c->user();

	my $application = $application_id ?
		$c->model('DB::Application')->find($application_id) :
		$user->find_related('applications',
			{
			decided_at => undef,
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

	# Create a new application if none found and no ID specified
	if (!$application)
		{
		die 'Cannot find application.' if ($application_id);
		$c->stash(
			{
			other    => 0,
			template => 'application/edit.tt',
			});
		}
	else
		{
		die 'Cannot find application.' if ($application->member_id() ne $user->member_id() && !$c->check_user_roles('board'));
		$c->stash(
			{
			template    => 'application/edit.tt',
			application => $application,
			other       => ($application->member_id() ne $user->member_id()),
			});
		}

	return
		if ($c->request()->method() eq 'GET');

	my $form = $c->request()->params();
	my $fail = {};

	foreach my $key (keys(%$form))
		{
		delete ($form->{$key})
			if ($form->{$key} eq '');
		}

	if ($form->{contact_phone})
		{
		my $phone = $form->{contact_phone};
		$phone =~ s/[^0-9]//g;
		$form->{contact_phone} = $phone;
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
		$c->model('DB')->schema()->txn_do(sub
			{
			if ($application)
				{
				$application->update($form) || die $!;

				$c->flash()->{auto_toast} =
					{
					title => 'Application Updated',
					text  => 'The application has been successfully updated.',
					};
				$c->response()->redirect($c->uri_for('/'));
				return;
				}

			$form->{member_id} = $user->member_id();
			$user->add_group(\$c->config()->{membership}->{apply_group}, 'Submitted application');

			$application = $c->model('DB::Application')->create($form) || die $!;
			my $queue = $c->model('DB::Action')->create(
				{
				action_type => 'application.create',
				row_id      => $application->application_id(),
				}) || die 'Unable to queue notification.';

			$c->stash(
				{
				template    => 'application/complete.tt',
				application => $application,
				});
			});
		}
	catch
		{
		$c->stash(
			{
			message     => { error => "$_" },
			application => $form
			});
		};
	}

sub print :Local
	{
	my ($self, $c, $application_id) = @_;
	my $user                        = $c->user();

	return if (!$user);

	my $application = $application_id ?
		$c->model('DB::Application')->find($application_id) :
		$user->find_related('applications',
			{
			decided_at => undef,
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

	if (!$application || ($application->member_id() ne $user->member_id() && !$c->check_user_roles('board')))
		{
		die 'Cannot find application.';
		}
	my $member = $application->member();

	my $pdf  = PDF::API2->open($c->config()->{home} . '/root/static/Hive Membership Application.pdf') || die $!;
	my $page = $pdf->openpage(1);
	my $font = $pdf->corefont('Helvetica');

	my $text = $page->text();
	$text->font($font, 16);
	$text->translate(107, 518);
	$text->text($member->fname() . ' ' . $member->lname());

	my $address = $application->address1();
	$address .= ' ' . $application->address2()
		if ($application->address2());
	$text->translate(122, 492);
	$text->text($address);

	$text->translate(94, 468);
	$text->text($application->city());

	$text->translate(352, 468);
	$text->text($application->state());

	my $zip = $application->zip();
	$zip =~ /(\d{5})(\d{0,4})/;
	$zip = "$1-$2" if $2;
	$text->translate(481, 468);
	$text->text($zip);

	my $phone = $member->phone();
	$phone =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
	$text->translate(108, 443);
	$text->text($phone);

	$text->translate(164, 417);
	$text->text($member->email());

	$text->translate(250, 390);
	$text->text($application->contact_name());

	$phone = $application->contact_phone();
	$phone =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
	$text->translate(444, 390);
	$text->text($phone);

	$c->response()->body($pdf->stringify());
	$c->response()->content_type('application/pdf');
	}

__PACKAGE__->meta->make_immutable;

1;
