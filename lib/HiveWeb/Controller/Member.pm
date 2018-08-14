package HiveWeb::Controller::Member;
use Moose;
use namespace::autoclean;
use LWP::UserAgent;
use HTTP::Request::Common;
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

sub charge :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $form    = $c->request()->params();
	my $config  = $c->config();
	my $credits = $config->{soda}->{add_amount};

	die
		if (!$form);

	my $ua  = LWP::UserAgent->new();

	my $data =
		{
		amount      => $config->{soda}->{cost},
		currency    => 'usd',
		description => $credits . ' Hive Soda Credits',
		source      => $form->{stripeToken},
		};
	my $req = POST 'https://api.stripe.com/v1/charges', $data || die $!;
	$req->header(Authorization => 'Bearer ' . $c->config()->{stripe}->{secret_key});
	my $res = $ua->request($req);

	if ($res->code() == 200)
		{
		$c->user()->add_vend_credits($credits);
		}
	$c->stash()->{response}      = $res->content();
	$c->stash()->{response_code} = $res->code();
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

sub pay :Local :Args(0)
	{
	my ($self, $c) = @_;

	$c->stash()->{template} = 'member/pay.tt';
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
