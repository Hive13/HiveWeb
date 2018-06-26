#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use HiveWeb;
use HiveWeb::Schema;

my $config = HiveWeb->config();
my $schema = HiveWeb::Schema->connect($config->{"Model::DB"}->{connect_info}) || die $!;

my $member_images = $schema->resultset('Member')     ->search({ member_image_id => { '!=' => undef } }, { alias => 'member_images' })->get_column('member_images.member_image_id')->as_query();
my $app_images    = $schema->resultset('Application')->search({ picture_id      => { '!=' => undef } }, { alias => 'app_images' })   ->get_column('app_images.picture_id')        ->as_query();
my $form_images   = $schema->resultset('Application')->search({ form_id         => { '!=' => undef } }, { alias => 'form_images' })  ->get_column('form_images.form_id')          ->as_query();

my $candidates = $schema->resultset('Image')->search(
	{
	-and =>
		[
		{	image_id => { '-not_in' => $member_images } },
		{	image_id => { '-not_in' => $app_images } },
		{	image_id => { '-not_in' => $form_images } },
		],
	},
	{
	select => 'image_id',
	}) || die $!;

$schema->txn_do(sub
	{
	my @ids;
	while (my $candidate = $candidates->next())
		{
		my $id = $candidate->image_id();
		my $in_audit_trail = $schema->resultset('AuditLog')->search({ notes => { ilike => "%$id%" } })->count();
		next if $in_audit_trail;
		push(@ids, $id);
		}
	$schema->resultset('Image')->search({ image_id => { -in => \@ids } })->delete();
	});
