package HiveWeb::Schema::ResultSet::IPNMessage;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use HiveWeb;
use LWP::UserAgent;
use JSON;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

sub subscr_payment
	{
	my ($self, $member, $parameters) = @_;

	return if ($parameters->{payment_status} ne 'Completed');

	my $schema = $self->result_source()->schema();

	my $existing = $schema->resultset('Payment')->search(
		{ 'ipn_message.txn_id' => $parameters->{txn_id} },
		{ join => 'ipn_message'}
		)->count();
	if ($existing)
		{
		$schema->resultset('Log')->new_log(
			{
			type    => 'ipn.duplicate',
			message => 'Payment already exists for IPN Message ' . $self->ipn_message_id()
			});
		return;
		}

	my $tz         = DateTime::TimeZone->new(name => 'America/Los_Angeles');
	my $payment_p  = DateTime::Format::Strptime->new( pattern => '%H:%M:%S %b %d, %Y', time_zone => $tz);
	my $payment_dt = $payment_p->parse_datetime($parameters->{payment_date});
	my $payment    = $member->create_related('payments',
		{
		ipn_message_id => $self->ipn_message_id(),
		payment_date   => $payment_dt,
		}) || die;

	my $pending = $member->search_related('member_mgroups', { 'mgroup.name' => 'pending_payments' }, { join => 'mgroup' });
	if ($pending->count())
		{
		$pending->delete();
		my $new_group = $schema->resultset('Mgroup')->find({ name => 'members' }) || die;
		$member->find_or_create_related('member_mgroups', { mgroup_id => $new_group->mgroup_id() });

		my $application = $member->find_related('applications',
			{
			decided_at => { '!=' => undef},
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			});

		if ($application)
			{
			$schema->resultset('Action')->create(
				{
				queuing_member_id => $member->member_id(),
				action_type       => 'application.pay',
				row_id            => $application->application_id(),
				}) || die 'Could not queue notification: ' . $!;
			}

		$schema->resultset('Action')->create(
			{
			queuing_member_id => $member->member_id(),
			action_type       => 'member.welcome',
			row_id            => $member->member_id(),
			}) || die 'Could not queue notification: ' . $!;

		my $slack = HiveWeb->config()->{slack};
		my $slack_invite =
			{
			first_name => $member->fname(),
			last_name  => $member->lname(),
			channels   => join(',', @{ $slack->{channels} }),
			email      => $member->email(),
			token      => $slack->{token},
			};

		my $ua = LWP::UserAgent->new();
		$ua->agent(sprintf("HiveWeb/%s (%s)", $HiveWeb::VERSION, $ua->agent));
		my $response = $ua->post($slack->{api}, $slack_invite);
		my $slack_result = decode_json($response->content());
		if (!$slack_result->{ok})
			{
			$schema->resultset('Log')->new_log(
				{
				type    => 'slack.invite_error',
				message => 'Cannot invite ' . $member->member_id() . ' to Slack: ' . $slack_result->{error}
				});;
			}
		}
	}

sub subscr_cancel
	{
	my ($self) = @_;

	my $schema = $self->result_source()->schema();

	$schema->resultset('Action')->create(
		{
		queuing_member_id => $self->member_id(),
		action_type       => 'member.confirm_cancel',
		row_id            => $self->member_id(),
		}) || die 'Could not queue notification: ' . $!;

	$schema->resultset('Action')->create(
		{
		queuing_member_id => $self->member_id(),
		action_type       => 'member.notify_cancel',
		row_id            => $self->member_id(),
		}) || die 'Could not queue notification: ' . $!;
	}

sub process
	{
	my ($self, $log_not_found) = @_;

	my $parameters = decode_json($self->raw());
	my $type       = $parameters->{txn_type};
	my $schema     = $self->result_source()->schema();
	my $payer      = $parameters->{payer_email};
	my $member_rs  = $schema->resultset('Member');
	my $member     = $member_rs->find({ email => $payer });
	if (!$member)
		{
		my @members = $member_rs->search({ paypal_email => $payer });
		if (scalar(@members) == 1)
			{
			$member = $members[0];
			}
		elsif (scalar(@members) > 1)
			{
			$schema->resultset('Log')->new_log(
				{
				type    => 'ipn.multiple_members',
				message => 'Multiple members with one PayPal e-mail in message ' . $self->ipn_message_id(),
				});
			}
		}
	my $member_id = $member ? $member->member_id() : undef;
	if (!$member)
		{
		if ($log_not_found)
			{
			$schema->resultset('Log')->new_log(
				{
				type    => 'ipn.unknown_email',
				message => 'Cannot locate member in message ' . $self->ipn_message_id(),
				});
			}
		}
	else
		{
		$self->update({ member_id => $member->member_id() });

		if ($type eq 'echeck' || $type eq 'subscr_payment')
			{
			$self->subscr_payment($member, $parameters);
			}
		elsif ($type eq 'subscr_cancel')
			{
			$self->subscr_cancel();
			}
		else
			{
			$schema->resultset('Log')->new_log(
				{
				type    => 'ipn.unknown_type',
				message => 'Unknown payment type in message ' . $self->ipn_message_id()
				});
			}
		}
	}

1;
