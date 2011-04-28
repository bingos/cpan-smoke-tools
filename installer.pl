use strict;
use warnings;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Configure;
use CPANPLUS::Backend;
use Getopt::Long;

my $host = '';
my $test = '';
my $uninstall = '';

GetOptions( 'test' => \$test, 'uninstall' => \$uninstall );

$ENV{PERL5_CPANIDX_URL} = '';
$ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

exit 0 unless @ARGV;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
$conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' )
  if check_install( module => 'CPANPLUS::Dist::YACSmoke' ) and !$uninstall;
$conf->set_conf( 'prereqs' => 2 );
$conf->set_conf( 'prefer_bin' => 1 );
$conf->set_conf( 'cpantest_reporter_args' => 
    {
      transport       => 'Socket',
      transport_args  => [ host => $host, port => 8080 ],
    },
  )
  if check_install( module => 'Test::Reporter::Transport::Socket' );
my $cb = CPANPLUS::Backend->new($conf);
foreach my $mod ( @ARGV ) {
  my $module = $cb->parse_module( module => $mod );
  next unless $module;
  if ( $uninstall ) {
    $module->uninstall();
  }
  else {
    $module->install( ( $test ? ( target => 'create' ) : () ) );
  }
}
exit 0;
