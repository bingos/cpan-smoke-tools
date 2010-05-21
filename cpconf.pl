use strict;
use warnings;
use Getopt::Long;
use CPANPLUS::Configure;
use Module::Load::Conditional qw[check_install];

my $mx;
my $email;
my $mirror;
my $socket;
my $port;

my @mirrors = (
  'http://cpan.hexten.net/',
  'http://cpan.cpantesters.org/',
  'ftp://ftp.funet.fi/pub/CPAN/',
);

GetOptions( 'mx=s', \$mx, 'email=s', \$email, 'mirror=s', \$mirror, 'socket=s', \$socket, 'port=s' => \$port );

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
unshift @mirrors, $mirror if $mirror;
my $hosts = [ ];
for ( @mirrors ) {
  my @parts = $_ =~ m|^(\w*)://([^/]*)(/.*)$|s;
  my $href;
  for my $key (qw[scheme host path]) {
    $href->{$key} = shift @parts;
  }
  push @$hosts, $href;
}

$conf->set_conf( cpantest_reporter_args => { transport => 'Socket', transport_args => [ host => $socket, port => $port ] } )
  if $socket and $port and check_install( module => 'Test::Reporter::Transport::Socket' );

$conf->set_conf( hosts => $hosts );
$conf->save();
exit 0;

