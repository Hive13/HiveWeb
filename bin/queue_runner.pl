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
		my $message =
			{
			from      => $mail_config->{from},
			from_name => $mail_config->{from_name},
			};
		if ($type =~ s/^application\.//)
			{
			my $application = $schema->resultset('Application')->find($action->row_id());
			if (!$application)
				{
				warn 'Cannot find referenced application ' . $action->row_id();
				return;
				}
			UUID::parse($application->application_id(), my $bin);
			my $enc_app_id = encode_base64($bin, '');
			$message->{to} = $app_config->{email_address};
			$message->{subject} = 'Membership Application: ' . $application->member()->fname() . ' ' . $application->member()->lname() . ' [' . $enc_app_id . ']';
			if (exists($app_config->{$type}))
				{
				my $app_create = $app_config->{$type};
				my $stash      =
					{
					application => $application,
					enc_app_id  => $enc_app_id,
					};

				$message->{body} = $c->view('TT')->render($c, $app_create->{temp_plain}, $stash);
				}
			else
				{
				warn $type;
				# Unknown action type; leave it alone.
				return;
				}
			}
		elsif ($type eq 'password.reset')
			{
			}
		else
			{
			# Unknown action type; leave it alone.
			return;
			}

		my $smtp = Net::SMTP->new(%{$mail_config->{'Net::SMTP'}});
		die "Could not connect to server\n"
			if !$smtp;

		if (exists($mail_config->{auth}))
			{
			$smtp->auth($mail_config->{from}, $mail_config->{auth})
				|| die "Authentication failed!\n";
			}

		$smtp->mail('<' . $message->{from} . ">\n");
		$smtp->to('<' . $message->{to} . ">\n");
		$smtp->data();
		$smtp->datasend('From: "' . $message->{from_name} . '" <' . $message->{from} . ">\n");
		$smtp->datasend('To: <' . $message->{to} . ">\n");
		$smtp->datasend('Subject: ' . $message->{subject} . "\n");
		$smtp->datasend("\n");
		$smtp->datasend($message->{body} . "\n");
		$smtp->dataend();
		$smtp->quit();
		#$action->delete();
		});
	}
