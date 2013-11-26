use strict;
use warnings;
use File::Spec;
use Capture::Tiny qw[capture_merged];
use Cwd;
use Perl::Version;
use Getopt::Long;
use FindBin qw[$Bin];

my $skiptests = 1;
my $tests;

GetOptions( 'skiptests', \$skiptests, 'tests', \$tests );

die unless @ARGV;

$skiptests = !$tests;

my $upscript = File::Spec->catfile($Bin,'update-smoker.pl');
die unless -e $upscript;

foreach my $arg ( @ARGV ) {
  my $path = Cwd::realpath($arg);
  next unless -d $path;
  my $confroot = File::Spec->catdir( $path, 'conf' );
  next unless -d $confroot;
  my @perls;
  opendir my $dir, $path or die "$!\n";
  while (my $item = readdir($dir)) {
    next unless $item =~ /^perl-/;
    push @perls, $item;
  }
  closedir $dir;
  next unless @perls;
  foreach my $perl ( sort _version_sort @perls ) {
    my $conf = File::Spec->catdir( $confroot, $perl );
    next unless -d $conf;
    my $perlexe = File::Spec->catfile($path,$perl,'bin','perl');
    unless ( -e $perlexe ) {
      # hmmm no perl there. Let's see if it is a dev release
      my @possibles = glob("${perlexe}5*");
      die "No perl executable found at '$path'\n" unless @possibles;
      $perlexe = shift @possibles;
    }
    #my $output = capture_merged { system($perlexe,'-e','printf "%vd", $^V;'); };
    #chomp $output;
    my $yactool = File::Spec->catfile($path,$perl,'bin','yactool');
    local $ENV{APPDATA} = $conf;
    my @cmd = ($perlexe,$upscript);
    push @cmd, '--skiptests' if $skiptests;
    system($yactool,'--flush');
    system(@cmd);
    system($yactool,'--flush');
  }
}
exit 0;

sub _version_sort {
  Perl::Version->new( ( split /-/, $a )[1] )->numify <=> Perl::Version->new( ( split /-/, $b )[1] )->numify
}
