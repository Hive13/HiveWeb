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
				my $app_create    = $app_config->{$type};
				$message->{stash} =
					{
					application => $application,
					enc_app_id  => $enc_app_id,
					action      => $action,
					};
				$message->{temp_plain} = $app_create->{temp_plain};

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
			my $member = $schema->resultset('Member')->find($action->row_id());
			if (!$member)
				{
				warn 'Cannot find referenced member ' . $action->row_id();
				return;
				}
			my $token              = $member->create_related('reset_tokens', { valid => 1 });
			my $forgot             = $mail_config->{forgot};
			$message->{to}         = $member->email();
			$message->{to_name}    = $member->fname() . ' ' . $member->lname();
			$message->{subject}    = $forgot->{subject};
			$message->{temp_plain} = $forgot->{temp_plain};
			$message->{stash}      =
				{
				token  => $token,
				member => $member,
				};
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

		my $body      = $c->view('TT')->render($c, $message->{temp_plain}, $message->{stash});
		my $to_header = '<' . $message->{to} . '>';
		$to_header    = '"' . $message->{to_name} . '" ' . $to_header
			if (exists($message->{to_name}));

		$smtp->mail('<' . $message->{from} . ">\n");
		$smtp->to('<' . $message->{to} . ">\n");
		$smtp->data();
		$smtp->datasend('From: "' . $message->{from_name} . '" <' . $message->{from} . ">\n");
		$smtp->datasend('To: ' . $to_header . "\n");
		$smtp->datasend('Subject: ' . $message->{subject} . "\n");
		$smtp->datasend("\n");
		$smtp->datasend($body . "\n");
		$smtp->dataend();
		$smtp->quit();
		#$action->delete();
		});
	}
