package HiveWeb::Controller::Admin::Reports;
use Moose;
use namespace::autoclean;
use JSON;
use DateTime::TimeZone;
use DateTime::Format::Strptime;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;
	}

sub membership_status :Local :Args(0)
	{
	my ($self, $schema) = @_;
	my $dtp        = $schema->storage()->datetime_parser();
	my $tz         = DateTime::TimeZone->new(name => 'America/Los_Angeles');
	my $payment_p  = DateTime::Format::Strptime->new( pattern => '%H:%M:%S %b %d, %Y', time_zone => $tz);

	my $badge_query = $schema->resultset('Badge')->search(
		{ member_id => { ident => 'me.member_id' } },
		{ alias => 'badges' }
		)->count_rs()->as_query() || die $!;
	my $pay_date_query = $schema->resultset('Payment')->search(
		{ member_id => { ident => 'me.member_id' } },
		{
		alias   => 'payment',
		columns => { pay_date => \'EXTRACT(DAYS FROM NOW() - MAX(payment_date))' },
		})->as_query() || die $!;
	my $pay_query = $schema->resultset('Payment')->search(
		{ member_id => { ident => 'me.member_id' } },
		{
		alias   => 'pay_date',
		columns => { pay_date => { max => 'payment_date' } },
		})->as_query() || die $!;
	my $member_query = $schema->resultset('MemberMgroup')->search(
		{
		name      => 'members',
		member_id => { ident => 'me.member_id' },
		},
		{ alias => 'mem_group', join => 'mgroup' }
		)->count_rs()->as_query() || die $!;

	my $members = $schema->resultset('Member')->search({ 'me.linked_member_id' => undef },
		{
		'+select' => [ $pay_date_query, $pay_query, $member_query, $badge_query ],
		'+as'     => [ 'days_since_paid', 'pay_date', 'is_member', 'badge_count' ],
		prefetch  => 'linked_members',
		});

	my $categories = {};

	while (my $member = $members->next())
		{
		my $category;
		my $days_paid = $member->get_column('days_since_paid');
		my $is_paid   = defined($days_paid) && $days_paid < 31;
		my $is_member = $member->get_column('is_member') > 0;
		my $has_badge = $member->get_column('badge_count') > 0;

		if ($is_paid && $is_member)
			{
			if ($has_badge)
				{
				$category = 'confirmed';
				}
			else
				{
				$category = 'no_badge';
				}
			}
		elsif (!$is_paid && $is_member)
			{
			my $paypal = $member->paypal_email();
			if (defined($paypal) && $paypal !~ /@/)
				{
				$category = 'override';
				}
			elsif (defined($days_paid))
				{
				$category = 'expired'
				}
			else
				{
				$category = 'unpaid';
				}
			}
		elsif ($is_paid && !$is_member)
			{
			$category = 'no_access';
			}

		if ($category)
			{
			$categories->{$category} //= [];
			my $pay_date = $member->get_column('pay_date');
			my $linked   = [];

			foreach my $link (@{ [ $member->linked_members() ] })
				{
				push(@$linked,
					{
					fname      => $link->fname(),
					lname      => $link->lname(),
					email      => $link->email(),
					created_at => $link->created_at(),
					});
				}
			if (defined($pay_date))
				{
				$pay_date = $dtp->parse_timestamp_with_time_zone($pay_date);
				}
			push(@{ $categories->{$category} },
				{
				fname        => $member->fname(),
				lname        => $member->lname(),
				email        => $member->email(),
				paypal_email => $member->paypal_email(),
				pay_date     => $pay_date,
				created_at   => $member->created_at(),
				linked       => $linked,
				});
			}
		}

	my $unknowns = $schema->resultset('IPNMessage')->search({ member_id => undef });
	while (my $unknown = $unknowns->next())
		{
		my $data = decode_json($unknown->raw());
		next if ($data->{txn_type} eq 'subscr_signup' || $data->{txn_type} eq 'subscr_modify');
		push(@{ $categories->{unknown} },
			{
			payment_type   => $data->{item_name},
			payment_status => $data->{payment_status},
			payer_email    => $unknown->payer_email(),
			paid_at        => $payment_p->parse_datetime($data->{payment_date}),
			});
		}

	return $categories;
	}

sub member :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $categories = $self->membership_status($c->model('DB'));
	$c->stash(
		{
		categories => $categories,
		show_pii   => 1,
		full       => 1,
		});
	}

sub membership :Local :Args(0) {}

__PACKAGE__->meta->make_immutable;

1;
