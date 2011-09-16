use strict;
use warnings;
use Getopt::Long;
use CPANPLUS::Configure;

my $mirror;
my @mirrors = (
  'http://cpan.hexten.net/',
  'http://cpan.cpantesters.org/',
  'http://cpan.dagolden.com/',
);

GetOptions( 'mirror=s', \$mirror, );

my $conf = CPANPLUS::Configure->new();
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

$conf->set_conf( hosts => $hosts );
$conf->save();
exit 0;
