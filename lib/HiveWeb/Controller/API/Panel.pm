package HiveWeb::Controller::API::Panel;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;
	}

sub move :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out       = $c->stash()->{out};
	my $in        = $c->stash()->{in};
	my $user      = $c->user();
	my $direction = lc($in->{direction} || 'left');
	my $member_id = $user->member_id();
	my $panels_rs = $c->model('DB::PanelMember')->search({}, { bind => [ $member_id ] });

	$c->model('DB')->txn_do(sub
		{
		my $prev;
		while (my $panel = $panels_rs->next())
			{
			next if (!$panel->can_view($c));
			if ( ($direction eq 'left' && $panel->panel_id() eq $in->{panel_id})
			  || ($direction eq 'right' && $prev && $prev->panel_id() eq $in->{panel_id}) )
				{
				return if (!$prev);
				$c->model('DB::MemberPanel')->update_or_create(
					{
					member_id  => $member_id,
					panel_id   => $panel->panel_id(),
					sort_order => $prev->sort_order(),
					}) || die $!;
				$c->model('DB::MemberPanel')->update_or_create(
					{
					member_id  => $member_id,
					panel_id   => $prev->panel_id(),
					sort_order => $panel->sort_order(),
					}) || die $!;
				$out->{response} = \1;
				return;
				}
			$prev = $panel;
			}
		});

	$out->{response} = \1;
	}

sub hide :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out     = $c->stash()->{out};
	my $in      = $c->stash()->{in};
	my $panel   = $c->model('DB::Panel')->find($in->{panel_id}) || return;

	$c->model('DB')->txn_do(sub
		{
		my $mp = $panel->update_or_create_related('member_panels',
			{
			member_id => $c->user()->member_id(),
			visible   => 'f',
			}) || die $!;
		});

	$out->{response} = \1;
	}

sub add :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $panels_rs = $c->model('DB::PanelMember')->search({}, { bind => [ $c->user()->member_id() ] });
	my $out       = $c->stash()->{out};
	my $in        = $c->stash()->{in};

	if (!$in->{panel_id})
		{
		my $panels = [];
		while (my $panel = $panels_rs->next())
			{
			next if (!$panel->can_view($c) || $panel->visible());
			push(@$panels,
				{
				panel_id => $panel->panel_id(),
				title    => $panel->title(),
				});
			}
		$out->{panels}   = $panels;
		$out->{response} = \1;
		}
	else
		{
		my $mp = $c->user()->update_or_create_related('member_panels',
			{
			panel_id => $in->{panel_id},
			visible  => 't',
			}) || die $!;
		$out->{response} = \1;
		}
	}

__PACKAGE__->meta->make_immutable;

1;
