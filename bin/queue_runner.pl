#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $done = 0;
while (!$done)
	{
	my $queue = $schema->resultset('Action')->search({}, { order_by => ['priority', 'queued_at'] }) || die $!;

	while (my $action = $queue->next())
		{
		$schema->txn_do(sub
			{
			my $type = lc($action->action_type());
			if ($type eq 'application.create')
				{
				warn "h";
				}
			elsif ($type eq 'application.attach_picture')
				{
				}
			elsif ($type eq 'application.mark_submitted')
				{
				}
			elsif ($type eq 'application.attach_form')
				{
				}
			elsif ($type eq 'application.password.reset')
				{
				}
			else
				{
				warn $type;
				# Unknown action type; leave it alone.
				next;
				}
			$action->delete();
			});
		}

	$done = 1;
	}
