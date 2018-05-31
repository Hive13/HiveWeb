requires 'Catalyst';

requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::DBIC';
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

requires 'Bytes::Random::Secure';
requires 'Math::Random::ISAAC::XS';

requires 'DateTime';
requires 'Digest::SHA';
requires 'HTTP::Request::Common';
requires 'JSON';
requires 'JSON::PP';
requires 'LWP::UserAgent';
requires 'MIME::Base64';
requires 'Net::SMTP';
requires 'Text::Markdown';
requires 'Try::Tiny';

# vim:set filetype=perl:
