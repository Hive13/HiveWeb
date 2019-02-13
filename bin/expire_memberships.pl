#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;
use Try::Tiny;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;
$config = $config->{cancellations};

my $debug   = 1;
my $message = [];
foreach my $freq (sort(keys(%{$config->{message_groups}})))
	{
	my $name  = $config->{message_groups}->{$freq};
	my $group = $schema->resultset('Mgroup')->find({ name => $name }) || die "Unknown group $name";
	push (@$message,
		{
		days     => $freq,
		name     => $name,
		group_id => $group->mgroup_id(),
		});
	}
die "Don't know when to send messages!" if (scalar(@$message) < 1);
my $begin_days = $message->[0]->{days};

my $pay_date_query = $schema->resultset('Payment')->search(
	{ member_id => { ident => 'me.member_id' } },
	{
	alias   => 'payment',
	columns => { pay_date => \'EXTRACT(DAYS FROM NOW() - MAX(payment_date))' },
	})->as_query() || die $!;
my $member_query = $schema->resultset('MemberMgroup')->search(
	{ 'mgroup.name' => $config->{member_group} },
	{ alias => 'mem_group', join => 'mgroup' }
	)->get_column('member_id')->as_query() || die $!;
my $mem_group_id = $schema->resultset('Mgroup')->find({ name => $config->{member_group} })->mgroup_id() || die $!;
my $pc_group_id  = $schema->resultset('Mgroup')->find({ name => $config->{pending_group} })->mgroup_id() || die $!;
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
			if ($days < $config->{expire_days})
				{
				$candidate->add_group($pc_group_id, undef, 'lapsed payment');
				while (my $link = $lpc->next())
					{
					$candidate->add_group($pc_group_id, undef, 'lapsed payment of linked account');
					}
				# Loop through the list of when to send messages BACKWARDS
				for (my $i = scalar(@$message) - 1; $i >= 0; $i--)
					{
					# Skip if we haven't hit number of days yet
					next if ($days < $message->[$i]->{days});
					# Skip if already sent message
					next if ($candidate->in_group($message->[$i]->{group_id}));
					$schema->resultset('Action')->create(
						{
						queuing_member_id => $candidate->member_id(),
						action_type       => $config->{late_email},
						row_id            => $candidate->member_id(),
						}) || die 'Could not queue notification: ' . $!;
					$candidate->add_group($message->[$i]->{group_id}, undef, 'lapsed payment');
					last;
					}
				}
			else
				{
				$candidate->remove_group($pc_group_id, undef, 'lapsed payment');
				$candidate->remove_group($mem_group_id, undef, 'lapsed payment');
				while (my $link = $lpc->next())
					{
					$link->remove_group($pc_group_id, undef, 'lapsed payment of linked account');
					$link->remove_group($mem_group_id, undef, 'lapsed payment of linked account');
					}
				}

			die "Debug Rollback" if $debug;
			});
		}
	catch
		{
		die $_ if !$debug;
		warn $_ if $debug && $_ !~ /^Debug Rollback/;
		};
	}
