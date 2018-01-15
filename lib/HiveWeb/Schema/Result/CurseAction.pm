use utf8;
package HiveWeb::Schema::Result::CurseAction;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/ UUIDColumns /);
__PACKAGE__->table('curse_action');

__PACKAGE__->add_columns(
  'curse_action_id',
  { data_type => 'uuid', is_foreign_key => 0, is_nullable => 0, size => 16 },
  'curse_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'path',
  { data_type => 'character varying', is_nullable => 0 },
  'action',
  { data_type => 'character varying', is_nullable => 0 },
  'message',
  { data_type => 'text', is_nullable => 0 },
);

__PACKAGE__->set_primary_key('curse_action_id');
__PACKAGE__->uuid_columns('curse_action_id');
__PACKAGE__->belongs_to(
  'curse',
  'HiveWeb::Schema::Result::Curse',
  { curse_id => 'curse_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

__PACKAGE__->meta->make_immutable;

sub TO_JSON
	{
	my $self = shift;
	return
		{
		curse_action_id => $self->curse_action_id(),
		curse           => $self->curse(),
		path            => $self->path(),
		action          => $self->action(),
		message         => $self->action(),
		};
	}
1;
