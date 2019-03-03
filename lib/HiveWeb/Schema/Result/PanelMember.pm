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
		panel.name,
		panel.title,
		COALESCE(member_panel.style, panel.style) AS style,
		panel.permissions,
		panel.large,
		COALESCE(member_panel.visible, panel.visible) AS visible
		FROM panel
		LEFT JOIN member_panel ON (member_panel.member_id = ? AND member_panel.panel_id = panel.panel_id)
		ORDER BY COALESCE(member_panel.sort_order, panel.sort_order)
');

__PACKAGE__->add_columns(
	'name',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'title',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'style',
	{ data_type => 'character varying', is_nullable => 0, size => 32 },
	'permissions',
	{ data_type => 'character varying', is_nullable => 1, size => 32 },
	'large',
	{ data_type => 'boolean', is_nullable => 0, default_value => 'f' },
	'visible',
	{ data_type => 'boolean', is_nullable => 0, default_value => 't' },
);

__PACKAGE__->meta->make_immutable;

1;
