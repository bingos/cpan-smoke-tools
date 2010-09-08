use strict;
use warnings;
use File::Spec;
use File::Path qw[rmtree];
use Cwd;
use FindBin qw[$Bin];

die unless @ARGV;

foreach my $arg ( @ARGV ) {
  my $path = Cwd::realpath($arg);
  next unless -d $path;
  my @perls;
  opendir my $dir, $path or die "$!\n";
  while (my $item = readdir($dir)) {
    next unless $item =~ /^perl-/;
    push @perls, $item;
  }
  closedir $dir;
  next unless @perls;
  foreach my $perl ( sort @perls ) {
    my $manpath = File::Spec->catdir($path,$perl,'man');
    rmtree( $manpath );
  }
}
exit 0;
