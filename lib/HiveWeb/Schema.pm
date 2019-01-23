use utf8;
package HiveWeb::Schema;

our $VERSION = 5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-02-24 20:22:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:duyvKW+0nZPtJ6ZFHsSZ8Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
