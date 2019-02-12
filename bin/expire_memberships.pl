#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $begin_days    = 35;
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
	my $days = $candidate->get_column('days_past');
	next if (!defined($days) || $days < $begin_days);
	warn $days;
	$schema->txn_do(sub
		{
		my $lpc = $candidate->linked_members();
		if ($days < $expire_days)
			{
			my $pc = $candidate->find_or_new_related('member_mgroups', { mgroup_id => $pc_group_id }) || die $!;

			if (!$pc->in_storage())
				{
				$candidate->create_related('changed_audits',
					{
					change_type        => 'add_group',
					changing_member_id => undef,
					notes              => "Added group $pc_group_id due to lapsed payment",
					}) || die $!;
				$pc->insert();
				}
			while (my $link = $lpc->next())
				{
				$link->find_or_new_related('member_mgroups', { mgroup_id => $pc_group_id }) || die $!;
				if (!$link->in_storage())
					{
					$link->create_related('changed_audits',
						{
						change_type        => 'add_group',
						changing_member_id => undef,
						notes              => "Added group $pc_group_id due to lapsed payment of linked account",
						}) || die $!;
					}
				}
			}
		else
			{
			my $pc = $candidate->find_related('member_mgroups', { mgroup_id => $pc_group_id });
			if ($pc)
				{
				$candidate->create_related('changed_audits',
					{
					change_type        => 'remove_group',
					changing_member_id => undef,
					notes              => "Removed group $pc_group_id due to lapsed payment",
					}) || die $!;
				$pc->delete();
				}
			my $mem = $candidate->find_related('member_mgroups', { mgroup_id => $mem_group_id });
			if ($mem)
				{
				$candidate->create_related('changed_audits',
					{
					change_type        => 'remove_group',
					changing_member_id => undef,
					notes              => "Removed group $mem_group_id due to lapsed payment",
					}) || die $!;
				$mem->delete();
				}
			while (my $link = $lpc->next())
				{
				my $pc = $link->find_related('member_mgroups', { mgroup_id => $pc_group_id }) || die $!;
				if ($pc)
					{
					$link->create_related('changed_audits',
						{
						change_type        => 'remove_group',
						changing_member_id => undef,
						notes              => "Removed group $pc_group_id due to lapsed payment of linked account",
						}) || die $!;
					$pc->delete();
					}
				my $mem = $link->find_related('member_mgroups', { mgroup_id => $mem_group_id }) || die $!;
				if ($mem)
					{
					$link->create_related('changed_audits',
						{
						change_type        => 'remove_group',
						changing_member_id => undef,
						notes              => "Removed group $mem_group_id due to lapsed payment of linked account",
						}) || die $!;
					$mem->delete();
					}
				}
			}

		die;
		});
	}
