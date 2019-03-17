#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;

my $c       = HiveWeb->new || die $!;
my $config  = $c->config();
my $schema  = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $queue   = $schema->resultset('Action')->search({ action_type => 'paypal.refresh' }) || die $!;
my $pending = $queue->count();

#return if !$pending;

my $candidates = $schema->resultset('IPNMessage')->search({ member_id => undef });
while (my $candidate = $candidates->next())
	{
	$schema->txn_do(sub
		{
		my $payer  = $candidate->payer_email();
		my $member = $schema->resultset('Member')->find({ email => $payer });
		if (!$member)
			{
			my @members = $schema->resultset('Member')->search({ paypal_email => $payer });
			return if (scalar(@members) != 1);
			$member = $members[0];
			}
		return if (!$member);

		$candidate->update({ member_id => $member->member_id() });
		$candidate->process();

		die $type;
		});
	}

#$queue->delete();
