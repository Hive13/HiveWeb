use strict;
use warnings;
use Test::More;


use Catalyst::Test 'HiveWeb';
use HiveWeb::Controller::Admin::Members;

ok( request('/admin/members')->is_success, 'Request should succeed' );
done_testing();
