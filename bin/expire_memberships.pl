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
$config = $config->{membership};

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
my $mem_group_id = $schema->resultset('Mgroup')->find({ name => $config->{member_group} })->mgroup_id() || die $!;
my $pc_group_id  = $schema->resultset('Mgroup')->find({ name => $config->{pending_group} })->mgroup_id() || die $!;
my $pe_group_id  = $schema->resultset('Mgroup')->find({ name => $config->{expire_group} })->mgroup_id() || die $!;
my $member_query = $schema->resultset('MemberMgroup')->search(
	{ mgroup_id => $mem_group_id },
	{ alias => 'mem_group' }
	)->get_column('member_id')->as_query() || die $!;
my $expire_query = $schema->resultset('MemberMgroup')->search(
	{
	mgroup_id => $pe_group_id,
	member_id => { ident => 'me.member_id' },
	},
	{ alias => 'exp_group' }
	)->count_rs()->as_query() || die $!;
my $candidates   = $schema->resultset('Member')->search(
	{
	paypal_email     => [ { 'like' => '%@%' }, undef ],
	linked_member_id => undef,
	member_id        => { '-in' => $member_query },
	},
	{
	'+select' => [ $pay_date_query, $expire_query ],
	'+as'     => [ 'days_past', 'expire' ],
	}) || die $!;

while (my $candidate = $candidates->next())
	{
	try
		{
		my $days   = $candidate->get_column('days_past') // return;
		my $expire = $candidate->get_column('expire');
		return if ($days < $begin_days && !$expire);
		$schema->txn_do(sub
			{
			printf("Looking at %s %s: %i/%i\n", $candidate->fname(), $candidate->lname(), $days, $expire);
			my $lpc = $candidate->linked_members();
			if ($expire)
				{
				if ($days > 31)
					{
					$candidate->mod_group({ group => $pe_group_id, notes => 'end of subscription', linked => 1, del => 1});
					$candidate->mod_group({ group => $mem_group_id, notes => 'end of subscription', linked => 1, del => 1});
					}
				}
			elsif ($days < $config->{expire_days})
				{
				$candidate->mod_group({ group => $pc_group_id, notes => 'lapsed payment', linked => 1});
				# Loop through the list of when to send messages BACKWARDS
				for (my $i = scalar(@$message) - 1; $i >= 0; $i--)
					{
					# Skip if we haven't hit number of days yet
					next if ($days < $message->[$i]->{days});
					# Done if already sent message
					last if ($candidate->in_group($message->[$i]->{group_id}));
					$schema->resultset('Action')->create(
						{
						queuing_member_id => $candidate->member_id(),
						action_type       => $config->{late_email},
						row_id            => $candidate->member_id(),
						}) || die 'Could not queue notification: ' . $!;
					$candidate->mod_group({ group => $message->[$i]->{group_id}, notes => 'lapsed payment' });
					last;
					}
				}
			else
				{
				$candidate->mod_group({ group => $pc_group_id, notes => 'lapsed payment', linked => 1, del => 1});
				$candidate->mod_group({ group => $mem_group_id, notes => 'lapsed payment', linked => 1, del => 1});
				}

			die "Debug Rollback" if !$real;
			});
		}
	catch
		{
		die $_ if $real;
		warn $_ if !$real && $_ !~ /^Debug Rollback/;
		};
	}
