use utf8;
package HiveWeb::Schema::Result::Member;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

use Crypt::Eksblowfish::Bcrypt qw* bcrypt en_base64 *;

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('members');

__PACKAGE__->add_columns(
  'member_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'fname',
  { data_type => 'varchar', is_nullable => 1, size => 255 },
  'lname',
  { data_type => 'varchar', is_nullable => 1, size => 255 },
  'email',
  { data_type => 'citext', is_nullable => 1 },
  'paypal_email',
  { data_type => 'varchar', is_nullable => 1, size => 255 },
  'phone',
  { data_type => 'bigint', is_nullable => 1 },
  'encrypted_password',
  { data_type => 'varchar', is_nullable => 1, size => 255, accessor => 'password' },
	'vend_credits',
  { data_type => 'integer', is_nullable => 1 },
	'vend_total',
  { data_type => 'integer', is_nullable => 1 },
	'created_at',
  {
    data_type     => 'timestamp without time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
	'updated_at',
  {
    data_type     => 'timestamp without time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
	'handle',
	{ data_type => 'citext', is_nullable   => 1	},
  'member_image_id',
  { data_type => 'uuid', is_nullable => 1, size => 16 },
	'door_count',
  { data_type => 'integer', is_nullable => 1 },
);

__PACKAGE__->uuid_columns('member_id');
__PACKAGE__->set_primary_key('member_id');
__PACKAGE__->add_unique_constraint('index_members_on_email', ['email']);
__PACKAGE__->add_unique_constraint('members_member_id_key', ['member_id']);

__PACKAGE__->has_many
	(
	'access_logs',
	'HiveWeb::Schema::Result::AccessLog',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'vend_logs',
	'HiveWeb::Schema::Result::VendLog',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'badges',
	'HiveWeb::Schema::Result::Badge',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'member_mgroups',
	'HiveWeb::Schema::Result::MemberMgroup',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'reset_tokens',
	'HiveWeb::Schema::Result::ResetToken',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'changed_audits',
	'HiveWeb::Schema::Result::AuditLog',
	{ 'foreign.changed_member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'changing_audits',
	'HiveWeb::Schema::Result::AuditLog',
	{ 'foreign.changing_member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->might_have
	(
	'image',
	'HiveWeb::Schema::Result::Image',
	{ 'foreign.image_id' => 'self.member_image_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'member_curses',
	'HiveWeb::Schema::Result::MemberCurse',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'issued_member_curses',
	'HiveWeb::Schema::Result::MemberCurse',
	{ 'foreign.issuing_member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'slots',
	'HiveWeb::Schema::Result::StorageSlot',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'requests',
	'HiveWeb::Schema::Result::StorageRequest',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'applications',
	'HiveWeb::Schema::Result::Application',
	{ 'foreign.member_id' => 'self.member_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->many_to_many('mgroups', 'member_mgroups', 'mgroup');
__PACKAGE__->many_to_many('curses', 'member_curses', 'curse');

sub TO_JSON
	{
	my $self    = shift;
	my $columns = { $self->get_columns() };
	my $dtp     = $self->result_source()->schema()->storage()->datetime_parser();
	my $lat;
	$lat = $dtp->parse_datetime($columns->{last_access_time})
		if (exists($columns->{last_access_time}) && $columns->{last_access_time});

	my @groups;
	my $mgs = $self->member_mgroups();
	while (my $mg = $mgs->next())
		{
		push(@groups, $mg->mgroup_id());
		}

	return
		{
		member_id       => $self->member_id(),
		fname           => $self->fname(),
		lname           => $self->lname(),
		email           => $self->email(),
		created_at      => $self->created_at(),
		groups          => \@groups,
		handle          => $self->handle(),
		phone           => $self->phone(),
		create_time     => $self->created_at(),
		vend_credits    => $self->vend_credits(),
		paypal_email    => $self->paypal_email(),
		member_image_id => $self->member_image_id(),
		door_count      => $self->door_count(),
		( exists($columns->{accesses}) ? ( accesses => $columns->{accesses} ) : () ),
		( exists($columns->{last_access_time}) ? ( last_access_time => $lat ) : () ),
		};
	}

sub TO_SUMMARY_JSON
	{
	my $self    = shift;

	return
		{
		member_id       => $self->member_id(),
		fname           => $self->fname(),
		lname           => $self->lname(),
		email           => $self->email(),
		handle          => $self->handle(),
		};
	}

sub make_salt
	{
	my $self   = shift;
	my $length = shift // 2;
	my @chars  = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
	my $salt   = '';

	for (my $i = 0; $i < $length; $i++)
		{
		$salt .= $chars[int(rand(scalar(@chars)))];
		}

	return $salt;
	}

sub check_password
	{
	my ($self, $pw) = @_;
	my $apw = $self->password();

	return ($apw eq bcrypt($pw, $apw))
		if ($apw =~ /^\$2/);

	return ($apw eq crypt($pw, $apw));
	}

sub set_password
	{
	my ($self, $pw) = @_;
	my $salt = '$6$' . $self->make_salt(16) . '$';

	$self->password(crypt($pw, $salt));
	$self->update();
	}

sub has_access
	{
	my ($self, $item) = @_;

	# Does the member have access to the item through any groups
	my $access = $self
		->search_related('member_mgroups')
		->search_related('mgroup')
		->search_related('item_mgroups', { item_id => $item->item_id() })
		->count();

	return $access > 0;
	}

sub do_vend
	{
	my $self    = shift;
	my $credits = $self->vend_credits() || 0;

	return 0
		if $credits < 1;

	my $count = $self->vend_total() || 0;
	$count++;
	$credits--;
	$self->update(
		{
		vend_total   => $count,
		vend_credits => $credits,
		});

	return 1;
	}

sub add_vend_credits
	{
	my $self   = shift;
	my $amount = shift;

	my $credits = $self->vend_credits() // 0;

	$credits += $amount;

	$self->update(
		{
		vend_credits => $credits,
		});

	return 1;
	}

sub list_slots
	{
	my $self  = shift;
	my @slots = $self->slots();
	my @ret;

	foreach my $slot (@slots)
		{
		my $location = $slot->location();
		my $lname;
		while ($location)
			{
			$lname = ' &rarr; ' . $lname
				if ($lname);
			$lname = $location->name() . $lname;
			$location = $location->parent();
			}
		push(@ret,
			{
			slot_id  => $slot->slot_id(),
			name     => $slot->name(),
			location => $lname,
			});
		}

	return @ret;
	}

__PACKAGE__->meta->make_immutable;
1;
