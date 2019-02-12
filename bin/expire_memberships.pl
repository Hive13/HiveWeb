#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;
use Try::Tiny;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $debug         = 1;
my $begin_days    = 40;
my $expire_days   = 90;
my $group_name    = 'members';
my $pc_group_name = 'pending_cancellations';

my $pay_date_query = $schema->resultset('Payment')->search(
	{ member_id => { ident => 'me.member_id' } },
	{
	alias   => 'payment',
	columns => { pay_date => \'EXTRACT(DAYS FROM NOW() - MAX(payment_date))' },
	})->as_query() || die $!;
my $member_query = $schema->resultset('MemberMgroup')->search(
	{ 'mgroup.name' => $group_name },
	{ alias => 'mem_group', join => 'mgroup' }
	)->get_column('member_id')->as_query() || die $!;
my $mem_group_id = $schema->resultset('Mgroup')->find({ name => $group_name })->mgroup_id() || die $!;
my $pc_group_id  = $schema->resultset('Mgroup')->find({ name => $pc_group_name })->mgroup_id() || die $!;
my $candidates   = $schema->resultset('Member')->search(
	{
	paypal_email     => [ { 'like' => '%@%' }, undef ],
	linked_member_id => undef,
	member_id        => { '-in' => $member_query },
	},
	{
	'+select' => $pay_date_query,
	'+as'     => 'days_past',
	}) || die $!;

while (my $candidate = $candidates->next())
	{
	try
		{
		my $days = $candidate->get_column('days_past');
		return if (!defined($days) || $days < $begin_days);
		warn $days;
		$schema->txn_do(sub
			{
			my $lpc = $candidate->linked_members();
			if ($days < $expire_days)
				{
				$candidate->add_group($pc_group_id, undef, "Added group $pc_group_id due to lapsed payment");
				while (my $link = $lpc->next())
					{
					$candidate->add_group($pc_group_id, undef, "Added group $pc_group_id due to lapsed payment of linked account");
					}
				}
			else
				{
				$candidate->remove_group($pc_group_id, undef, "Removed group $pc_group_id due to lapsed payment");
				$candidate->remove_group($mem_group_id, undef, "Removed group $mem_group_id due to lapsed payment");
				while (my $link = $lpc->next())
					{
					$link->remove_group($pc_group_id, undef, "Removed group $pc_group_id due to lapsed payment of linked account");
					$link->remove_group($mem_group_id, undef, "Removed group $mem_group_id due to lapsed payment of linked account");
					}
				}

			die "Debug Rollback" if $debug;
			});
		}
	catch
		{
		die $_ if !$debug;
		warn $_ if $debug && $_;
		};
	}
