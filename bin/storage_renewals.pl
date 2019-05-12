#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;
use Try::Tiny;
use Getopt::Long;

my $real = 0;

GetOptions(
	'real'   => \$real,
);

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $remind_group_query = $schema->resultset('MemberMgroup')->search(
	{
	name => $config->{storage}->{remind_group}
	},
	{
	alias => 'remind_group',
	join  => 'mgroup',
	},
	)->get_column('member_id')->as_query() || die $!;
my $candidates = $schema->resultset('StorageSlot')->search(
	{
	expire_date    => { '<=' => \['now() + ?', $config->{storage}->{remind} ] },
	'me.member_id' => { '-not_in' => $remind_group_query },
	},
	{
	join    => 'member',
	columns => ['me.slot_id', 'member.member_id', 'me.name'],
	}) || die $!;

while (my $candidate = $candidates->next())
	{
	try
		{
		$schema->txn_do(sub
			{
			my $member = $candidate->member();
			$schema->resultset('Action')->create(
				{
				queuing_member_id => $member->member_id(),
				action_type       => 'storage.renew_remind',
				row_id            => $candidate->slot_id(),
				});
			$member->mod_group({ group => \$config->{storage}->{remind_group}, notes => 'Slot ' . $candidate->name() . ' expiring' });
			die "Debug Rollback" if !$real;
			});
		}
	catch
		{
		die $_ if $real;
		warn $_ if !$real && $_ !~ /^Debug Rollback/;
		};
	}
