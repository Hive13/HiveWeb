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
		$candidate->process();
		die;
		});
	}

#$queue->delete();
