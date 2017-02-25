package HiveWeb::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
		ENCODING           => 'utf-8',
		CATALYST_VAR       => 'Catalyst',
		WRAPPER            => 'wrapper.tt',
);

=head1 NAME

HiveWeb::View::HTML - TT View for HiveWeb

=head1 DESCRIPTION

TT View for HiveWeb.

=head1 SEE ALSO

L<HiveWeb>

=head1 AUTHOR

Greg Arnold,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
