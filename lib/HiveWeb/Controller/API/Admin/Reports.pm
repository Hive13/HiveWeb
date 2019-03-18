package HiveWeb::Controller::API::Admin::Reports;
use Moose;
use namespace::autoclean;

use JSON;
use DateTime;

BEGIN { extends 'Catalyst::Controller'; }

sub membership_total :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	my $in  = $c->stash()->{in};
	my $out = $c->stash()->{out};

	my $date  = DateTime->now()->subtract(months => 1);

	my $start = DateTime->new( year => $date->year(), month => $date->month() );
	my $end   = $start->clone()->add(months => 1);
	
	my @payments = $c->model('DB::Payment')->search(
		{
		payment_date => { '>=' => $start, '<' => $end },
		},
		{
		join    => 'ipn_message',
		columns => { raw => 'ipn_message.raw' },
		})->hashref();
	
	$out->{totals} = {};
	foreach my $payment (@payments)
		{
		my $parameters = decode_json($payment->{raw});

		if (defined(my $item = $parameters->{item_number}))
			{
			$out->{totals}->{$item}++;
			}
		}
	
	my @non = $c->model('DB::Member')->active()->non_paypal()->search({},
		{
		columns => ['fname', 'lname', 'paypal_email'],
		})->hashref();

	$out->{non_paypal} = \@non;
	$out->{response}   = \1;
	}

__PACKAGE__->meta->make_immutable;

1;
