package HiveWeb::Schema::Result::PanelMember;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('panels_for_member');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition('
	SELECT
		panel.panel_id,
		panel.name,
		panel.title,
		COALESCE(member_panel.style, panel.style) AS style,
		panel.permissions,
		panel.large,
		COALESCE(member_panel.visible, panel.visible) AS visible,
		COALESCE(member_panel.sort_order, panel.sort_order) AS sort_order
		FROM panel
		LEFT JOIN member_panel ON (member_panel.member_id = ? AND member_panel.panel_id = panel.panel_id)
		ORDER BY 8
');

__PACKAGE__->add_columns(
	'panel_id',
	{ data_type => 'uuid', is_nullable => 0, size => 32 },
	'name',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'title',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'style',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'permissions',
	{ data_type => 'character varying', is_nullable => 1, size => 32 },
	'large',
	{ data_type => 'boolean', is_nullable => 0 },
	'visible',
	{ data_type => 'boolean', is_nullable => 0 },
	'sort_order',
	{ data_type => 'integer', is_nullable => 0 },
);

__PACKAGE__->meta->make_immutable;

sub can_view
	{
	my ($self, $c) = @_;

	my $perm = $self->permissions();

	return 1 if (!defined($perm));

	return !!$c->user()
		if ($perm eq '' || $perm eq 'user');

	return $c->check_user_roles($perm);
	}

1;
