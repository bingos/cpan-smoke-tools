use strict;
use warnings;
use Getopt::Long;
use CPANPLUS::Configure;
use Module::Load::Conditional qw[check_install];

my $relay;
my $port;

GetOptions( 'relay=s', \$relay, 'port=s' => \$port );

die "No --relay or --port specified, please do so\n" unless $relay and $port;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( cpantest_reporter_args => { transport => 'Socket', transport_args => [ host => $relay, port => $port ] } )
  if $relay and $port and check_install( module => 'Test::Reporter::Transport::Socket' );
$conf->save();
exit 0;
