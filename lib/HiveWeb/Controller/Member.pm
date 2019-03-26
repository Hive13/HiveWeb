package HiveWeb::Controller::Member;
use Moose;
use namespace::autoclean;
use Bytes::Random::Secure qw(random_bytes);
use Convert::Base32;
use Imager::QRCode;

BEGIN { extends 'Catalyst::Controller' }

sub verify_user_data
	{
	my ($self, $c, $form, $has_pass) = @_;

	my $message = {};

	my $different_paypal = delete($form->{different_paypal});

	if ($different_paypal)
		{
		if ($form->{paypal_email} && $form->{paypal_email} !~ /.+@.+\..+/)
			{
			$message->{paypal_email} = "You must specify a valid PayPal e-mail address or leave it blank if you do not use PayPal.";
			}
		}
	else
		{
		$form->{paypal_email} = undef;
		}
	if ($form->{handle})
		{
		my $search = { handle => $form->{handle} };
		$search->{member_id} = { '!=' => $c->user()->member_id() }
			if ($c->user());
		my $member = $c->model('DB::Member')->search($search);
		if ($member->count())
			{
			$message->{handle} = 'That handle is already in use.';
			}
		}
	else
		{
		$form->{handle} = undef;
		}
	if ($form->{phone})
		{
		my $phone = $form->{phone};
		$phone =~ s/[^0-9]//g;
		$form->{phone} = $phone;
		}
	else
		{
		$form->{phone} = undef;
		}
	if (!$form->{email} || $form->{email} eq '' || $form->{email} !~ /.+@.+\..+/)
		{
		$message->{email} = "You must specify a valid e-mail address.";
		}
	else
		{
		my $search = { email => $form->{email} };
		$search->{member_id} = { '!=' => $c->user()->member_id() }
			if ($c->user());
		my $member = $c->model('DB::Member')->search($search);
		if ($member->count())
			{
			$message->{email} = 'That e-mail address has already been registered.';
			}
		}
	if (!$form->{fname} || $form->{fname} eq '')
		{
		$message->{fname} = "You must specify your first name.";
		}
	if (!$form->{lname} || $form->{lname} eq '')
		{
		$message->{lname} = "You must specify your last name.";
		}

	if ($has_pass && $form->{password1} ne $form->{password2})
		{
		$message->{password} = "&lsaquo; The passwords don't match.";
		}

	return $message
		if (keys %$message);
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('profile');
	}

sub profile :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'member/profile.tt';

	return
		if ($c->request()->method() eq 'GET');

	my $form    = $c->request()->params();
	my $message = $self->verify_user_data($c, $form, 0);

	if ($message)
		{
		$c->stash(
			{
			vals    => $form,
			message => $message,
			});
		return;
		}

	$c->user()->update($form) || die $!;
	$c->response()->redirect($c->uri_for('/'));
	}

sub totp_qrcode :Local :Args(0)
	{
	my ($self, $c) = @_;

	return if ($c->user()->totp_secret());

	my $secret = $c->session()->{candidate_secret} || random_bytes(16);
	$c->session()->{candidate_secret} = $secret;

	my $qrcode = Imager::QRCode->new(
		{
		size          => 5,
		margin        => 2,
		version       => 1,
		level         => 'H',
		casesensitive => 1,
		lightcolor    => Imager::Color->new(255, 255, 255),
		darkcolor     => Imager::Color->new(0, 0, 0),
		});
	my $data;
	my $img = $qrcode->plot(sprintf('otpauth://totp/%s?secret=%s&issuer=Hive13+intweb', $c->user()->email(), encode_base32($secret)));
	$img->write(data => \$data, type => 'png')
		or die 'Failed to write: ' . $img->errstr;

	$c->response()->body($data);
	$c->response()->content_type('image/png');
	}

sub register :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'member/profile.tt';

	return
		if ($c->request()->method() eq 'GET');

	my $form    = $c->request()->params();
	my $message = $self->verify_user_data($c, $form, 1);

	if ($message)
		{
		$c->stash(
			{
			vals    => $form,
			message => $message,
			});
		return;
		}

	my $password = $form->{password1};
	delete($form->{password1});
	delete($form->{password2});

	$c->model('DB')->schema()->txn_do(
	sub
		{
		my $member = $c->model('DB::Member')->create($form) || die $!;
		$member->set_password($password);
		$c->authenticate({ password => $password, 'dbix_class' => { result => $member } }) || die $!;
		});

	$c->response()->redirect($c->uri_for('/'));
	}

sub pay :Local :Args(0) {}

sub pay_complete :Local :Args(0) {}

sub cancel :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $user       = $c->user();
	my $member_id  = $user->member_id();
	my $request    = $c->request();
	my $survey     = $c->model('DB::Survey')->find($c->config()->{cancellations}->{survey_uuid}) || die 'Can\'t load survey.';

	if ($request->method() eq 'GET')
		{
		$c->stash(
			{
			survey   => $survey,
			template => 'survey.tt',
			});
		return;
		}

	$c->model('DB')->txn_do(sub
		{
		my $expired = $c->model('DB::Payment')->find({ member_id => $member_id },
			{
			select => \"max(payment_date) + interval '1 month' <= now()",
			as     => 'expired',
			});
		if ($expired->get_column('expired'))
			{
			$user->remove_group(\'members', undef, 'cancellation confirmation');
			}
		else
			{
			$user->add_group(\'pending_expiry', undef, 'cancellation confirmation');
			}

		my $response = $c->model('DB::SurveyResponse')->fill_out($user, $survey, $request->params()) || die $!;

		$c->model('DB::Action')->create(
			{
			queuing_member_id => $member_id,
			action_type       => 'notify.term',
			row_id            => $response->survey_response_id(),
			}) || die 'Could not queue notification: ' . $!;
		$c->flash()->{auto_toast} =
			{
			title => 'Resignation Submitted',
			text  => 'Your resignation has been submitted.',
			};
		$c->response()->redirect($c->uri_for('/'));
		});
	}

sub requests :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $user     = $c->user() || return;
	my @slots    = $user->list_slots();
	my @requests = $user->requests()->search({}, { order_by => { -desc => 'created_at' } })->all();

	$c->stash(
		{
		template => 'member/requests.tt',
		slots    => \@slots,
		markdown => new Text::Markdown,
		requests => \@requests,
		});
	}

__PACKAGE__->meta->make_immutable;

1;
