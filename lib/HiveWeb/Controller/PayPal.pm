package HiveWeb::Controller::PayPal;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use LWP::UserAgent;
use Data::Dumper;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

BEGIN { extends 'Catalyst::Controller' }

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
			if (my $dup = $c->model('DB::Payment')->find({ paypal_txn_id => $parameters->{txn_id} }))
				{
				$log->error('Duplicate txn_id as payment ' . $dup->payment_id() . ': ' . Data::Dumper::Dumper($parameters));
				return;
				}

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
					$log->error('Multiple members with one PayPal e-mail: ' . Data::Dumper::Dumper($parameters));
					$member = $members[0];
					}
				}
			if (!$member)
				{
				$log->error('Cannot locate member: ' . Data::Dumper::Dumper($parameters));
				}
			my $member_id = $member ? $member->member_id() : undef;

			my $payment_type =
				$c->model('DB::PaymentType')->find({ name => $parameters->{payment_type} })
				// $c->model('DB::PaymentType')->find({ name => 'unknown' })
				// die;
			my $tz         = DateTime::TimeZone->new(name => 'America/Los_Angeles');
			my $payment_p  = DateTime::Format::Strptime->new( pattern => '%H:%M:%S %b %d, %Y', time_zone => $tz);
			my $payment_dt = $payment_p->parse_datetime($parameters->{payment_date});

			my $raw = Data::Dumper->new([$parameters]);
			$raw->Terse(1)->Indent(0);
			my $payment = $c->model('DB::Payment')->create(
				{
				member_id        => $member_id,
				payment_type_id  => $payment_type->id(),
				payment_currency => $parameters->{mc_currency},
				payment_amount   => $parameters->{mc_gross},
				payment_date     => $payment_dt,
				paypal_txn_id    => $parameters->{txn_id},
				payer_email      => $payer,
				raw       => $raw->Dump(),
				});

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
		$c->log()->debug($_);
		};
	}

__PACKAGE__->meta->make_immutable;

1;
