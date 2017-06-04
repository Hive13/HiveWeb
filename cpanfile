requires 'Catalyst';

requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Authorization::ACL';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Authentication::Store::LDAP';
requires 'Catalyst::Action::RenderView';

requires 'Config::General';
requires 'MooseX::NonMoose';
requires 'Crypt::Eksblowfish::Bcrypt';

requires 'DBIx::Class';
requires 'DBIx::Class::UUIDColumns';
requires 'DBD::Pg';
requires 'DateTime::Format::Pg';

# vim:set filetype=perl:
