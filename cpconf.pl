use strict;
use warnings;
use Getopt::Long;
use CPANPLUS::Configure;

my $mx;
my $email;
my $protocol;

GetOptions( 'mx=s', \$mx, 'email=s', \$email, 'protocol=s', \$protocol );

die "No --email specified, please do so\n" unless $email;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( verbose => 1 );
$conf->set_conf( cpantest => 'dont_cc' );
$conf->set_conf( cpantest_mx => $mx ) if $mx;
$conf->set_conf( email => $email );
$conf->set_conf( makeflags => 'UNINST=1' );
$conf->set_conf( buildflags => 'uninst=1' );
$conf->set_conf( enable_custom_sources => 0 );
$conf->set_conf( show_startup_tip => 0 );
$conf->set_conf( write_install_logs => 0 );
my $hosts = $conf->get_conf( 'hosts' );
unshift @$hosts, _hosts( $protocol );
$conf->set_conf( hosts => $hosts );
$conf->save();
exit 0;

sub _hosts {
  my $prot = shift || 'http';
  return 
   (
    {
      scheme => 'ftp',
      host   => 'cpan.hexten.net',
      path   => '/',
    },
    {
      scheme => 'ftp',
      host   => 'cpan.cpantesters.org',
      path   => '/CPAN/',
    },
   ) if $prot eq 'ftp';

  return 
   (
    {
      scheme => 'http',
      host   => 'cpan.hexten.net',
      path   => '/',
    },
    {
      scheme => 'http',
      host   => 'cpan.cpantesters.org',
      path   => '/',
    },
   );
}
