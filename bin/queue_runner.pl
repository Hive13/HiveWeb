#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;
use UUID;
use MIME::Base64;
use Getopt::Long;
use Email::MIME;
use Email::Address::XS;

my $do_smtp = 0;
my $delete  = 0;

GetOptions(
	'email'  => \$do_smtp,
	'delete' => \$delete,
);

my $c           = HiveWeb->new || die $!;
my $config      = $c->config();
my $app_config  = $config->{application};
my $mail_config = $config->{email};
my $schema      = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;
my $queue       = $schema->resultset('Action')->search({}, { order_by => ['priority', 'queued_at'] }) || die $!;
my $smtp;
my @emails;

while (my $action = $queue->next())
	{
	$schema->txn_do(sub
		{
		my $key  = 'email.' . lc($action->action_type());
		my $path = $key;
		$path =~ s/\./\//g;
		my $message =
			{
			from       => $mail_config->{from},
			from_name  => $mail_config->{from_name},
			temp_plain => $c->config_path($key, 'temp_plain'),
			temp_html  => $c->config_path($key, 'temp_html'),
			subject    => $c->config_path($key, 'subject'),
			to         => $c->config_path($key, 'to'),
			};
		$message->{temp_plain} //= $path . '_plain.tt' if (-f $c->path_to('root', 'src', $path . '_plain.tt'));
		$message->{temp_html}  //= $path . '_html.tt' if (-f $c->path_to('root', 'src', $path . '_html.tt'));
		return if (!$message->{temp_plain} && !$message->{temp_html});

		my $row_name  = $c->config_path($key, 'row_as') // 'row';
		my $row_class = $c->config_path($key, 'row');
		my $row       = $schema->resultset($row_class)->find($action->row_id());
		if (!$row)
			{
			warn "Cannot find referenced $row_name " . $action->row_id();
			return;
			}
		$message->{stash} =
			{
			$row_name => $row,
			base_url  => $config->{base_url},
			};
		if ($message->{to} =~ /^$row_name\.member$/ && $row->can('member'))
			{
			my $member = $row->member();
			if (!$member)
				{
				warn 'No member for ' . $row_name;
				return;
				}
			$message->{to} = { $member->email() => $member->fname() . ' ' . $member->lname() };
			}
		elsif ($message->{to} eq 'member' && $row_name eq 'member')
			{
			$message->{to} = { $row->email() => $row->fname() . ' ' . $row->lname() };
			}
		elsif ($message->{to} eq 'storage')
			{
			$message->{to} = [];
			my $users = $schema->resultset('MemberMgroup')->search(
				{
				'mgroup.name' => 'storage',
				},
				{
				join     => 'mgroup',
				prefetch => 'member',
				});

			while (my $user = $users->next())
				{
				my $member = $user->member();
				push(@{ $message->{to} }, { $member->email() => $member->fname() . ' ' . $member->lname() });
				}
			}
		if ($key eq 'email.member.password_reset')
			{
			$message->{stash}->{token} = $row->create_related('reset_tokens', { valid => 1 });
			}
		if ($key =~ /^email\.application\./)
			{
			UUID::parse($row->application_id(), my $bin);
			my $enc_app_id = encode_base64($bin, '');
			$message->{subject} = 'Membership Application: ' . $row->member()->fname() . ' ' . $row->member()->lname() . ' [' . $enc_app_id . ']';
			$message->{stash}->{action} = $action;
			}

		if (ref($message->{to}) ne 'ARRAY')
			{
			$message->{to} = [ $message->{to} ];
			}

		my @parts;

		if ($message->{temp_html})
			{
			push(@parts, Email::MIME->create(
				attributes =>
					{
					content_type => 'text/html',
					},
				body => $c->view('TT')->render($c, $message->{temp_html}, $message->{stash}),
				));
			}

		if ($message->{temp_plain})
			{
			push(@parts, Email::MIME->create(
				attributes =>
					{
					content_type => 'text/plain',
					},
				body => $c->view('TT')->render($c, $message->{temp_plain}, $message->{stash}),
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

		push (@emails,
			{
			email => $email,
			to    => $message->{to},
			from  => $message->{from},
			});

		$action->delete()
			if ($delete);
		});
	}

if ($do_smtp && scalar(@emails))
	{
	$smtp = Net::SMTP->new(%{$mail_config->{'Net::SMTP'}});
	die "Could not connect to server\n"
		if !$smtp;

	if (exists($mail_config->{auth}))
		{
		$smtp->auth($mail_config->{authuser}, $mail_config->{auth})
			|| die "Authentication failed!\n";
		}

	foreach my $message (@emails)
		{
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
			$message->{email}->header_str_set(To => $to_header->as_string());

			if ($do_smtp)
				{
				$smtp->mail('<' . $message->{from} . ">\n");
				$smtp->to('<' . $to_env . ">\n");
				$smtp->data();
				$smtp->datasend($message->{email}->as_string() . "\n");
				$smtp->dataend();
				}
			}
		}
	$smtp->quit();
	}
elsif (scalar(@emails))
	{
	foreach my $message (@emails)
		{
		print($message->{email}->as_string() . "\n");
		}
	}
