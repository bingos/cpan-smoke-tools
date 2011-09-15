use strict;
use warnings;
use CPANPLUS::Configure;
my $conf = CPANPLUS::Configure->new();
#$conf->set_conf( prefer_bin => 1 );
$conf->set_program( make => '/usr/bin/gmake' );
$conf->save();
exit 0;
