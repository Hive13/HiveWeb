use utf8;
package HiveWeb::Schema::Result::IPNMessage;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;

use HiveWeb;
use LWP::UserAgent;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

extends 'HiveWeb::DBIx::Class::Core';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime InflateColumn::Serializer });
__PACKAGE__->table('ipn_message');

__PACKAGE__->add_columns(
  'ipn_message_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
	'received_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
	'txn_id',
  { data_type => 'character varying', is_nullable => 1 },
	'payer_email',
  { data_type => 'character varying', is_nullable => 0 },
	'raw',
  {
	data_type        => 'text',
	is_nullable      => 0,
	serializer_class => 'JSON',
	},
);

__PACKAGE__->uuid_columns('ipn_message_id');
__PACKAGE__->set_primary_key('ipn_message_id');

__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

sub TO_JSON
	{
	my $self = shift;

	return
		{
		ipn_message_id => $self->ipn_message_id(),
		member_id      => $self->member_id(),
		received_at    => $self->received_at(),
		txn_id         => $self->txn_id(),
		payer_email    => $self->payer_email(),
		data           => $self->raw(),
		};
	}

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
		$member->mod_group({ group => \'pending_payments', notes => 'initial payment', del => 1, linked => 1 });
		$member->mod_group({ group => \'members', notes => 'initial payment', linked => 1 });

		my $application = $member->find_related('applications',
			{
			decided_at => { '!=' => undef},
			},
			{
			order_by => { -desc => 'updated_at' },
			rows     => 1,
			}) || return;

		$schema->resultset('Action')->create(
			{
			queuing_member_id => $member->member_id(),
			action_type       => 'application.pay',
			row_id            => $application->application_id(),
			}) || die 'Could not queue notification: ' . $!;

		$schema->resultset('Action')->create(
			{
			action_type => 'member.welcome',
			row_id      => $member->member_id(),
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
				});
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

	my $parameters = $self->raw();
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
		elsif ($type eq 'subscr_modify' || $type eq 'subscr_signup')
			{
			# Just ignore these
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

__PACKAGE__->meta->make_immutable;
1;
