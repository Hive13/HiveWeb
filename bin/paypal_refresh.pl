#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;
use JSON;

my $c           = HiveWeb->new || die $!;
my $config      = $c->config();
my $app_config  = $config->{application};
my $mail_config = $config->{email};
my $schema      = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $queue   = $schema->resultset('Action')->search({ action_type => 'paypal.refresh' }) || die $!;
my $pending = $queue->count();

#return if !$pending;

my $candidates = $schema->resultset('IPNMessage')->search({ member_id => undef });
while (my $candidate = $candidates->next())
	{
	$schema->txn_do(sub
		{
		my $parameters = decode_json($candidate->raw());
		my $type       = $parameters->{txn_type};
		my $payer      = $candidate->payer_email();
		my $member     = $c->model('DB::Member')->find({ email => $payer });
		if (!$member)
			{
			my @members = $c->model('DB::Member')->search({ paypal_email => $payer });
			return if (scalar(@members) != 1);
			$member = $members[0];
			}
		return if (!$member);
		my $member_id  = $member->member_id();
		$candidate->update({ member_id => $member_id });

		if ($type eq 'echeck' || $type eq 'web_accept' || $type eq 'subscr_payment')
			{
			HiveWeb::Controller::PayPal->subscr_payment($c, $member, $parameters, $candidate);
			}
		elsif ($type eq 'subscr_cancel')
			{
			HiveWeb::Controller::PayPal->subscr_cancel($c, $member, $parameters, $candidate);
			}

		die $type;
		});
	}

#$queue->delete();
