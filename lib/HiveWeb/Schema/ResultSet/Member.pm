package HiveWeb::Schema::ResultSet::Member;

use strict;
use warnings;
use base 'HiveWeb::DBIx::Class::ResultSet';

sub active
	{
	my $self = shift;

	my $group_query = $self->result_source()->schema()->resultset('MemberMgroup')->search(
		{ 'mgroup.name' => 'members' }, { join => 'mgroup', alias => 'active_members' })->get_column('member_id')->as_query();

	return $self->search({ member_id => { -in => $group_query } });
	}

sub non_paypal
	{
	my $self = shift;

	return $self->search({ paypal_email => { -not_like => '%@%' } });
	}

1;
