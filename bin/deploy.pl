#!/usr/bin/env perl

use aliased 'DBIx::Class::DeploymentHandler' => 'DH';

use FindBin;
use lib $FindBin::Bin . '/../lib';
use HiveWeb;
use HiveWeb::Schema;

my $c           = HiveWeb->new || die $!;
my $config      = $c->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $dh = DH->new(
	{
	schema              => $schema,
	script_directory    => "$FindBin::Bin/../dbicdh",
	databases           => 'PostgreSQL',
	sql_translator_args => { add_drop_table => 0 },
	force_overwrite     => 1,
	});

$dh->prepare_deploy();

#$dh->prepare_install();

$dh->prepare_upgrade(
	{
	from_version => 2,
	to_version   => 3,
	});

#$dh->install();
