package HiveWeb::Controller::API;
use Moose;
use namespace::autoclean;

use JSON::PP;
use Digest::SHA qw(sha512_hex);
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

HiveWeb::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub make_hash
  {
	state $js     = JSON::PP->new();
	state $sorter = sub { $JSON::PP::a cmp $JSON::PP::b; };
	my $json      = shift;
	my $key       = shift;
	my $hash_str  = $js->sort_by($sorter)->encode($json);
	print STDERR $hash_str . "\n";
	
	return uc(sha512_hex($key . $hash_str));
	}

sub hash_it
  {
	my $in_json  = shift;
	my $key      = shift;
	my $out_json = {};
	
	$out_json->{data} = $in_json;
	if (defined($key))
		{
		my $random = [];
		for (my $i = 0; $i < 16; $i++)
			{
			push(@{$random}, int(rand(256)));
			}
		$in_json->{random}    = $random;
		$out_json->{checksum} = make_hash($in_json, $key);
		}
	
	return $out_json;
	}

sub has_access :Private
	{
	my $c        = shift;
	my $badge_no = shift;
	my $iname    = shift;
	my $item     = $c->model('DB::Item')->find( { name => $iname } );
	my $badge    = $c->model('DB::Badge')->find( { badge_number => $badge_no } );
	my $member;
	
	if (defined($badge))
		{
		$member = $badge->member();
		}
	else
		{
		$member = $c->model('DB::Member')->find( { accesscard => $badge_no } );
		}
	
	return "Invalid badge"
		if (!defined($member));
	return "Invalid item"
		if (!defined($item));
	return "Locked out"
		if ($member->is_lockedout());
	
	# Does the member have access to the item through any groups
	my $access = $item
		->search_related('item_mgroups')
		->search_related('mgroup')
		->search_related('member_mgroups', { member_id => $member->member_id() })
		->count();
	
	# Log the access
	$c->model('DB::AccessLog')->create(
		{
		member_id => $member->member_id(),
		item_id   => $item->item_id(),
		granted   => ($access > 0) ? 1 : 0,
		});
	
	return $access > 0 ? undef : "Access denied";
	}


sub begin :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{in} = $c->req()->body_data();
	$c->stash()->{out} = {};
	}

sub end :Private
	{
	my ($self, $c) = @_;

	$c->detach($c->view('JSON'));
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;
	
	$c->response->body('Matched HiveWeb::Controller::API in API.');
	}

sub access :Local
	{
	my ($self, $c) = @_;
	my $in     = $c->stash()->{in};
	my $out    = $c->stash()->{out};
	my $odata  = {};
	my $device = $c->model('DB::Device')->find({ name => $in->{device} });
	my $data   = $in->{data};

	if (!defined($device))
		{
		$out->{response} = JSON::PP->false();
		$out->{error} = 'Cannot find device.';
		return;
		}
	
	my $shasum = make_hash($data, $device->key());
	if ($shasum ne uc($in->{checksum}))
		{
		$out->{response} = JSON::PP->false();
		$out->{error} = 'Invalid checksum.';
		return;
		}
	
	$odata->{response} = JSON::PP->true();
	my $operation = lc($in->{operation} // 'access');
	if ($operation eq 'access')
		{
		my $badge  = $data->{badge};
		my $item   = $data->{location} // $data->{item};
		my $access = has_access($c, $badge, $item);		
		my $d_i    = $device
			->search_related('device_items')
			->search_related('item', { name => $item } );
		
		if ($d_i->count() < 1)
			{
			$odata->{access} = JSON::PP->false();
			$odata->{error} = "Device not authorized for " . $item;
			}
		elsif (defined($access))
			{
			$odata->{access} = JSON::PP->false();
			$odata->{error} = $access;
			}
		else
			{
			$odata->{access} = JSON::PP->true();
			}
		}
	else
		{
		$odata->{response} = JSON::PP->false();
		$odata->{error} = 'Invalid operation.';
		}
	$c->stash()->{out} = hash_it($odata, $device->key());
	} 

=encoding utf8

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
