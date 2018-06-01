use utf8;
package HiveWeb::Schema::Result::AccessHeatmap;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
 
 __PACKAGE__->table_class('DBIx::Class::ResultSource::View');
 
 # For the time being this is necessary even for virtual views
 __PACKAGE__->table('access_heatmap');
 
 #
 # ->add_columns, etc.
 #
 __PACKAGE__->add_columns(
 	'access_count',
	{ data_type => 'integer' },
	'dow',
	{ data_type => 'integer' },
	'hour',
	{ data_type => 'integer' },
	'qhour',
	{ data_type => 'integer' },
);

 
 # do not attempt to deploy() this view
 __PACKAGE__->result_source_instance->is_virtual(1);
 
 __PACKAGE__->result_source_instance->view_definition(q[
	SELECT
		COUNT(*) AS access_count, EXTRACT(dow FROM access_time) AS dow,
			EXTRACT(hour FROM access_time) AS hour, (EXTRACT(minute FROM access_time)::integer / 15) AS qhour
		FROM access_log
		WHERE granted = 't'
		GROUP BY 2, 3, 4
		ORDER BY 2, 3, 4
]);
