use strict;
use warnings;
use File::Spec;
use IPC::Cmd qw[can_run];
use Capture::Tiny qw[capture_merged];
use Perl::Version;
use FindBin qw[$Bin];
use Cwd;

die unless @ARGV;

my $zapscript = File::Spec->catfile( $Bin, 'zaptmp.pl' );
my $minismokebox = File::Spec->catfile($Config::Config{installsitescript},'minismokebox');
die "No 'minismokebox' found\n" unless $minismokebox;

my $shell;

$shell = can_run('bash');
$shell = can_run('sh') unless $shell;
$shell = '/bin/sh' unless $shell;

open my $script, '>', 'rotate.sh' or die "$!\n";
print $script "#!$shell", "\n";
print $script "while true;\ndo\n";

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
    my $output = capture_merged { system($perlexe,'-e','printf "%vd", $^V;'); };
    chomp $output;
    my $cpanp = File::Spec->catfile($path,$perl,'bin','cpanp' . ( $perlexe =~ /\Q$output\E$/ ? $output : '' ) );
    my $yactool = File::Spec->catfile($path,$perl,'bin','yactool');
    print $script "export PERL5_YACSMOKE_BASE=$conf\n";
    print $script "$cpanp -x --update_source\n";
    print $script "$minismokebox --perl $perlexe --recent --random\n";
    print $script "$yactool --flush\n";
    print $script "$^X $zapscript\n";
  }
}
print $script "ipcrm -m all\nipcrm -s all\n" if $^O eq 'netbsd';
print $script "done\n";
close $script;
chmod 0755, 'rotate.sh' or die "$!\n";
exit 0;

sub _version_sort {
  Perl::Version->new( ( split /-/, $a )[1] )->numify <=> Perl::Version->new( ( split /-/, $b )[1] )->numify
}
