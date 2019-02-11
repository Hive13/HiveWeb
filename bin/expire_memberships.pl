#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $begin_date = 35;
my $group_name = 'members';

my $pay_date_query = $schema->resultset('Payment')->search(
	{ payment_date => { '<=' => \"now() - interval '$begin_date days'" } },
	{ alias => 'payment' })->get_column('member_id')->as_query() || die $!;
my $member_query = $schema->resultset('MemberMgroup')->search(
	{ 'mgroup.name' => $group_name },
	{ alias => 'mem_group', join => 'mgroup' }
	)->get_column('member_id')->as_query() || die $!;
my $candidates = $schema->resultset('Member')->search(
	{
	paypal_email     => [ { 'like' => '%@%' }, undef ],
	linked_member_id => undef,
	member_id        => { '-not_in' => $pay_date_query, '-in' => $member_query },
	}) || die $!;

my @a = $candidates->all();
