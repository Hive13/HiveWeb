use strict;
use warnings;

use HiveWeb;

my $app = HiveWeb->apply_default_middlewares(HiveWeb->psgi_app);
$app;

