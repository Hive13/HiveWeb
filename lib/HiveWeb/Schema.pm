use utf8;
package HiveWeb::Schema;

our $VERSION = 9;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
