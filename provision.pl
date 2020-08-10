use strict;
use warnings;
use Sys::Hostname qw[hostname];
use File::Spec;
use File::Path qw[mkpath];
use File::Glob qw[bsd_glob];
use File::Copy qw[copy];
use IPC::Cmd qw[can_run];
use Cwd qw[chdir];

my $git = can_run('git');
die "No 'git' no dice\n" unless $git;

my $host = +( split m!\.!, hostname )[0];
my $home = bsd_glob("~");
my $pit = File::Spec->catdir( $home, 'pit' );
mkpath( File::Spec->catdir( $home, '.smokebrew' ) );
mkpath( File::Spec->catdir( $home, '.smokebox'  ) );
mkpath( $pit );
mkpath( File::Spec->catdir( $pit, $_ ) ) for qw[build jail authors];
chdir $pit;
system( $git, 'clone', 'git://github.com/bingos/cpan-smoke-tools.git', 'tools' );
copy( File::Spec->catfile( $pit, qw[tools vimrc] ), File::Spec->catfile( $home, '.vimrc' ) );
#copy( File::Spec->catfile( $pit, qw[tools minismokebox] ), File::Spec->catfile( $home, qw[.smokebox minismokebox] ) );
copy( File::Spec->catfile( $pit, qw[tools smokebrew.cfg] ), File::Spec->catfile( $home, qw[.smokebrew smokebrew.cfg] ) );
copy( File::Spec->catfile( $pit, qw[tools cpansmoke.ini] ), File::Spec->catfile( $pit, 'cpansmoke.ini' ) );
{
  open my $msbox, '<', File::Spec->catfile( $pit, qw[tools minismokebox] ) or die "$!\n";
  local $/;
  my $content = <$msbox>;
  close $msbox;
  $content =~ s!CHANGE!$host!ms;
  open my $hmsbox, '>', File::Spec->catfile( $home, qw[.smokebox minismokebox] ) or die "$!\n";
  print {$hmsbox} $content;
  close $hmsbox;
}
