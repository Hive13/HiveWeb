package HiveWeb::Controller::PayPal;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use JSON;

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

	$response->content_type('text/plain');
	try
		{
		$c->model('DB')->txn_do(sub
			{
			my $parameters = $c->request()->parameters();
			my $payer      = $parameters->{payer_email};
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
					$c->model('DB::Log')->new_log(
						{
						type    => 'ipn.multiple_members',
						message => "Multiple members with one PayPal e-mail: $json",
						});
					$member = $members[0];
					}
				}
			my $member_id = $member ? $member->member_id() : undef;

			my $message = $c->model('DB::IPNMessage')->create(
				{
				member_id   => $member_id,
				txn_id      => $parameters->{txn_id},
				payer_email => $payer,
				raw         => $json,
				}) || die;

			if (!$member)
				{
				$c->model('DB::Log')->new_log(
					{
					type    => 'ipn.unknown_email',
					message => 'Cannot locate member in message ' . $message->ipn_message_id(),
					});
				}
			else
				{
				$message->process();
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
