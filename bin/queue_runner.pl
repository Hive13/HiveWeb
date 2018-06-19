#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;
use UUID;
use MIME::Base64;

my $c           = HiveWeb->new || die $!;
my $config      = $c->config();
my $app_config  = $config->{application};
my $mail_config = $config->{email};
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $queue = $schema->resultset('Action')->search({}, { order_by => ['priority', 'queued_at'] }) || die $!;

while (my $action = $queue->next())
	{
	$schema->txn_do(sub
		{
		my $type = lc($action->action_type());
		my $application;
		if ($type =~ /^application\./)
			{
			if (!($application = $schema->resultset('Application')->find($action->row_id())))
				{
				warn 'Cannot find referenced application ' . $action->row_id();
				next;
				}
			}
		if ($type eq 'application.create')
			{
			my $bin;
			my $message_id;
			UUID::parse($application->application_id(), $bin);
			my $enc_app_id = encode_base64($bin, '');
			my $app_create = $app_config->{create};
			my $to         = $app_config->{email_address};
			my $from       = $mail_config->{from};
			my $subject    = 'Membership Application: ' . $application->member()->fname() . ' ' . $application->member()->lname() . ' [' . $enc_app_id . ']';
			my $stash      =
				{
				application => $application,
				enc_app_id  => $enc_app_id,
				};

			my $body = $c->view('TT')->render($c, $app_create->{temp_plain}, $stash);

			my $smtp = Net::SMTP->new(%{$mail_config->{'Net::SMTP'}});
			die "Could not connect to server\n"
				if !$smtp;

			if (exists($mail_config->{auth}))
				{
				$smtp->auth($from, $mail_config->{auth})
					|| die "Authentication failed!\n";
				}

			$smtp->mail('<' . $from . ">\n");
			$smtp->to('<' . $to . ">\n");
			$smtp->data();
			$smtp->datasend('From: "' . $mail_config->{from_name} . '" <' . $from . ">\n");
			$smtp->datasend('To: <' . $to . ">\n");
			$smtp->datasend('Subject: ' . $subject . "\n");
			$smtp->datasend("\n");
			$smtp->datasend($body . "\n");
			$smtp->dataend();
			$smtp->quit();
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
		#$action->delete();
		});
	}
