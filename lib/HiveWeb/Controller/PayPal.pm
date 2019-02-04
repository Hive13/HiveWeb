package HiveWeb::Controller::PayPal;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use LWP::UserAgent;

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
			if (my $dup = $c->model('DB::Payment')->find({ paypal_txn_id => $parameters->{txn_id} }))
				{
				$log->error('Duplicate txn_id as payment ' . $dup->payment_id() . ': ' . Data::Dumper::Dumper($parameters));
				return;
				}

			my $member = $c->model('DB::Member')->find({ email => $parameters->{payer_email} });
			if (!$member)
				{
				my @members = $c->model('DB::Member')->search({ paypal_email => $parameters->{payer_email} });
				if (scalar(@members) == 1)
					{
					$member = $members[0];
					}
				else
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

			my $payment = $c->model('DB::Payment')->create(
				{
				member_id => $member_id,
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
