#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $begin_date    = 35;
my $group_name    = 'members';
my $pc_group_name = 'pending_cancellations';

my $pay_date_query = $schema->resultset('Payment')->search(
	{ payment_date => { '<=' => \"now() - interval '$begin_date days'" } },
	{ alias => 'payment' })->get_column('member_id')->as_query() || die $!;
my $member_query = $schema->resultset('MemberMgroup')->search(
	{ 'mgroup.name' => $group_name },
	{ alias => 'mem_group', join => 'mgroup' }
	)->get_column('member_id')->as_query() || die $!;
my $pc_group    = $schema->resultset('Mgroup')->find({ name => $pc_group_name }) || die $!;
my $pc_group_id = $pc_group->mgroup_id();
my $candidates  = $schema->resultset('Member')->search(
	{
	paypal_email     => [ { 'like' => '%@%' }, undef ],
	linked_member_id => undef,
	member_id        => { '-not_in' => $pay_date_query, '-in' => $member_query },
	}) || die $!;

while (my $candidate = $candidates->next())
	{
	$schema->txn_do(sub
		{
		my $pc  = $candidate->find_or_new_related('member_mgroups', { mgroup_id => $pc_group_id }) || die $!;
		my $lpc = $candidate->linked_members();

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

		die;
		});
	}
