#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;
use Getopt::Long;
use Email::MIME;
use Email::Address::XS;

my $do_smtp = 0;
my $delete  = 0;

GetOptions(
	'email'  => \$do_smtp,
);

my $c           = HiveWeb->new || die $!;
my $config      = $c->config();
my $report      = $config->{reports}->{membership};
my $mail_config = $config->{email};
my $schema      = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;
my $smtp;

my $message =
	{
	from      => $mail_config->{from},
	from_name => $mail_config->{from_name},
	to        => [ $report->{to} ],
	subject   => $report->{subject},
	};

my $data = HiveWeb::Controller::Admin::Reports->membership_status($schema);

$message->{stash} =
	{
	show_pii   => 0,
	full       => 0,
	subject    => $report->{subject},
	categories => $data->{categories},
	totals     => $data->{totals},
	};

my @parts;
if ($report->{temp_html})
	{
	push(@parts, Email::MIME->create(
		attributes =>
			{
			content_type => 'text/html',
			},
		body => $c->view('ReportTT')->render($c, $report->{temp_html}, $message->{stash}),
	));
	}

if ($report->{temp_plain})
	{
	push(@parts, Email::MIME->create(
		attributes =>
			{
			content_type => 'text/plain',
			},
		body => $c->view('ReportTT')->render($c, $report->{temp_plain}, $message->{stash}),
	));
	}

my $email = Email::MIME->create(
	attributes =>
		{
		content_type => 'multipart/alternative',
		},
	header_str =>
		[
		Subject => $message->{subject},
		From    => Email::Address::XS->new($message->{from_name}, $message->{from}),
		],
	parts => \@parts,
);


if ($do_smtp)
	{
	$smtp = Net::SMTP->new(%{$mail_config->{'Net::SMTP'}});
	die "Could not connect to server\n"
		if !$smtp;

	if (exists($mail_config->{auth}))
		{
		$smtp->auth($mail_config->{from}, $mail_config->{auth})
			|| die "Authentication failed!\n";
		}
	
	foreach my $to (@{ $message->{to} })
		{
		my $to_env;
		my $to_header;
		if (ref($to) eq 'HASH')
			{
			$to_env = (keys(%$to))[0];
			$to_header = Email::Address::XS->new((values(%$to))[0], $to_env);
			}
		else
			{
			$to_env = $to;
			$to_header = Email::Address::XS->new(undef, $to_env);
			}
		$email->header_str_set(To => $to_header->as_string());

		if ($do_smtp)
			{
			$smtp->mail('<' . $message->{from} . ">\n");
			$smtp->to('<' . $to_env . ">\n");
			$smtp->data();
			$smtp->datasend($email->as_string() . "\n");
			$smtp->dataend();
			}
		}
	$smtp->quit();
	}
else
	{
	print($email->as_string() . "\n");
	}
