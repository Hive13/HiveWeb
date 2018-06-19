#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;
use Net::IMAP::Simple;
use Email::MIME;
use MIME::Base64;
use UUID;

my $config = HiveWeb->config();
my $mail_config = $config->{email};
my $imap_config = $mail_config->{'Net::IMAP'};
my $wanted_list = $mail_config->{list};

my $client = Net::IMAP::Simple->new($imap_config->{host}, %$imap_config) || die 'Unable to connect to IMAP: ' . $Net::IMAP::Simple::errstr;
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

$client->login($config->{email}->{from}, $config->{email}->{auth}) || die $!;

my $count = $client->select('INBOX');

for (my $i = 1; $i <= $count; $i++)
	{
	next if ($client->seen($i));
	my $message = $client->get($i);
	my $email   = Email::MIME->new(join('', @$message));
	
	my $list = $email->header('List-ID');
	if (!$list || $list ne $wanted_list)
		{
		$client->see($i);
		next;
		}
	
	my $subject = $email->header('Subject');

	if ($subject !~ /\[([a-zA-Z0-9.\/]+={0,3})\]/)
		{
		$client->see($i);
		next;
		}
	
	my $uuid;
	UUID::unparse(decode_base64($1), $uuid);
	my $application = $schema->resultset('Application')->find($uuid);
	if (!$application)
		{
		$client->see($i);
		next;
		}
	
	print 'From: ' . $email->header('From') . " -- $uuid\n";
	my @parts = $email->parts();

	for (my $i = 0; $i < @parts; $i++)
		{
		my $part = $parts[$i];
		my $ct   = $part->content_type();

		if ($ct =~ /^multipart\/alternative/i)
			{
			@parts = $part->parts;
			$i = 0;
			redo;
			}

		if ($ct =~ /^text\/plain/)
			{
			my $body = $part->body();
			$body =~ s/.+[\r\n]+--[\r\n\t ]+//;
			warn $body;
			}
		}
	
	
	#print Data::Dumper::Dumper(\@parts);
	$client->unsee($i);
	}
