package HiveWeb::View::ReportTT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
		ENCODING           => 'utf-8',
		CATALYST_VAR       => 'Catalyst',
		WRAPPER            => 'report_wrapper.tt',
);

1;
