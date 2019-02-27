package HiveWeb::Controller::PayPal;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use LWP::UserAgent;
use JSON;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

BEGIN { extends 'Catalyst::Controller' }

sub subscr_payment
	{
	my ($self, $c, $member, $parameters, $message) = @_;

	return if ($parameters->{payment_status} ne 'Completed');

	my $existing = $c->model('DB::Payment')->search(
		{ 'ipn_message.txn_id' => $parameters->{txn_id} },
		{ join => 'ipn_message'}
		)->count();
	if ($existing)
		{
		$c->log()->error('Payment already exists for IPN Message ' . $message->ipn_message_id());
		return;
		}

	my $tz         = DateTime::TimeZone->new(name => 'America/Los_Angeles');
	my $payment_p  = DateTime::Format::Strptime->new( pattern => '%H:%M:%S %b %d, %Y', time_zone => $tz);
	my $payment_dt = $payment_p->parse_datetime($parameters->{payment_date});
	my $payment    = $member->create_related('payments',
		{
		ipn_message_id => $message->ipn_message_id(),
		payment_date   => $payment_dt,
		}) || die;

	my $pending = $member->search_related('member_mgroups', { 'mgroup.name' => 'pending_payments' }, { join => 'mgroup' });
	if ($pending->count())
		{
		$pending->delete();
		my $new_group = $c->model('DB::Mgroup')->find({ name => 'members' }) || die;
		$member->find_or_create_related('member_mgroups', { mgroup_id => $new_group->mgroup_id() });

		my $application = $member->find_related('applications',
			{
			decided_at => { '!=' => undef},
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

		$c->model('DB::Action')->create(
			{
			queuing_member_id => $member->member_id(),
			action_type       => 'application.pay',
			row_id            => $application->application_id(),
			}) || die 'Could not queue notification: ' . $!;

		$c->model('DB::Action')->create(
			{
			queuing_member_id => $member->member_id(),
			action_type       => 'member.welcome',
			row_id            => $member->member_id(),
			}) || die 'Could not queue notification: ' . $!;
		}
	}

sub subscr_cancel
	{
	my ($self, $c, $member, $parameters, $message) = @_;

	$c->model('DB::Action')->create(
		{
		queuing_member_id => $member->member_id(),
		action_type       => 'member.confirm_cancel',
		row_id            => $member->member_id(),
		}) || die 'Could not queue notification: ' . $!;

	$c->model('DB::Action')->create(
		{
		queuing_member_id => $member->member_id(),
		action_type       => 'member.notify_cancel',
		row_id            => $member->member_id(),
		}) || die 'Could not queue notification: ' . $!;
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('ipn');
	}

sub ipn :Local :Args(0)
	{
	my ($self, $c) = @_;
	my $response   = $c->response();
	my $log        = $c->log();

	$response->content_type('text/plain');
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $parameters = $c->request()->parameters();
			my $payer      = $parameters->{payer_email};
			my $type       = $parameters->{txn_type};
			my $json       = encode_json($parameters);

			my $member = $c->model('DB::Member')->find({ email => $payer });
			if (!$member)
				{
				my @members = $c->model('DB::Member')->search({ paypal_email => $payer });
				if (scalar(@members) == 1)
					{
					$member = $members[0];
					}
				elsif (scalar(@members) > 1)
					{
					$log->error("Multiple members with one PayPal e-mail: $json");
					$member = $members[0];
					}
				}
			my $member_id = $member ? $member->member_id() : undef;

			my $message = $c->model('DB::IPNMessage')->create(
				{
				member_id   => $member_id,
				txn_id      => $parameters->{txn_id},
				payer_email => $payer,
				raw         => encode_json($parameters),
				}) || die;

			if (!$member)
				{
				$log->error('Cannot locate member in message ' . $message->ipn_message_id());
				}
			else
				{
				if ($type eq 'echeck' || $type eq 'subscr_payment')
					{
					$self->subscr_payment($c, $member, $parameters, $message);
					}
				elsif ($type eq 'subscr_cancel')
					{
					$self->subscr_cancel($c, $member, $parameters, $message);
					}
				else
					{
					$log->error('Unknown payment type in message ' . $message->ipn_message_id());
					}
				}

			# Verify the transaction with PayPal
			$parameters->{cmd} = '_notify-validate';
			my $ua = LWP::UserAgent->new();
			$ua->agent(sprintf("HiveWeb/%s (%s)", $HiveWeb::VERSION, $ua->agent));
			my $response = $ua->post($c->config()->{paypal}->{gateway_url}, $parameters);
			die if ($response->content() ne 'VERIFIED');
			});
		$response->status(200);
		$response->body('');
		}
	catch
		{
		$response->status(500);
		$response->body('not_ok');
		$c->log()->error($_);
		};
	}

__PACKAGE__->meta->make_immutable;

1;
