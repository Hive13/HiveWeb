use utf8;
package HiveWeb::Schema::Result::StorageSlot;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

use Net::SMTP;

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("storage_slot");

__PACKAGE__->add_columns(
  "slot_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "character varying", is_nullable => 0, size => 32 },
  "member_id",
  { data_type => "uuid", is_nullable => 1 },
  "location_id",
  { data_type => "uuid", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("slot_id");
__PACKAGE__->uuid_columns("slot_id");
__PACKAGE__->resultset_attributes( { order_by => ['name'] } );

__PACKAGE__->belongs_to(
  "member",
  "HiveWeb::Schema::Result::Member",
  { "foreign.member_id" => "self.member_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "location",
  "HiveWeb::Schema::Result::StorageLocation",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;

sub assign
	{
	my ($self, $member_id, $c) = @_;
	my $config   = $c->config()->{email};
	my $schema   = $self->result_source()->schema();
	my $template = $config->{assigned_slot};

	return
		if (!$member_id || !$c);
	$member_id = $member_id->member_id()
		if (ref($member_id));

	my $member = $schema->resultset('Member')->find($member_id)
		|| die 'Invalid Member.';

	my $to     = $member->email();
	my $from   = $config->{from};
	my $stash  =
		{
		member => $member,
		slot   => $self,
		};

	my $body = $c->view('TT')->render($c, $template->{temp_plain}, $stash);

	my $smtp = Net::SMTP->new(%{$config->{'Net::SMTP'}});
	die "Could not connect to server\n"
		if !$smtp;

	if (exists($config->{auth}))
		{
		$smtp->auth($from, $config->{auth})
			|| die "Authentication failed!\n";
		}

	$smtp->mail('<' . $from . ">\n");
	$smtp->to('<' . $to . ">\n");
	$smtp->data();
	$smtp->datasend('From: "' . $config->{from_name} . '" <' . $from . ">\n");
	$smtp->datasend('To: "' . $member->fname() . ' ' . $member->lname() . '" <' . $to . ">\n");
	$smtp->datasend('Subject: ' . $template->{subject} . "\n");
	$smtp->datasend("\n");
	$smtp->datasend($body . "\n");
	$smtp->dataend();
	$smtp->quit();
	$self->update({ member_id => $member_id }) || die $!;
	}

sub TO_JSON
	{
	my $self = shift;

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		location_id => $self->location_id(),
		};
	}

sub TO_FULL_JSON
	{
	my $self = shift;

	return
		{
		slot_id     => $self->slot_id(),
		name        => $self->name(),
		member_id   => $self->member_id(),
		member      => $self->member(),
		location_id => $self->location_id(),
		location    => $self->location(),
		};
	}

sub hierarchy
	{
	my $self = shift;
	my $sep  = shift // '&rarr;';

	my $lname;
	my $location = $self->location();
	while ($location)
		{
		$lname = " $sep $lname"
			if ($lname);
		$lname = $location->name() . $lname;
		$location = $location->parent();
		}

	return $lname;
	}
1;
