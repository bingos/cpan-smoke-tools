use strict;
use warnings;
use File::Spec;
use Config;
use Module::Load::Conditional qw[can_load];

my $opt = shift;
$opt = '' unless $opt and $opt eq '--lite';

my $prefix = $Config::Config{prefix};
{
  local $ENV{ ( can_load( modules => { 'File::HomeDir' => 0.0 } ) ? 'PERL5_CPANPLUS_HOME' : 'APPDATA' ) } = $prefix;
  system($^X, 'tools/cpconf.pl');
  system($^X, 'tools/updater.pl', '--all');
  system($^X, 'tools/installer.pl', 'List::UtilsBy');
  system($^X, 'tools/installer.pl', 'App::SmokeBrew::Plugin::BINGOS') unless $opt;
  system($^X, 'tools/installer.pl', 'App::SmokeBox::Mini::Plugin::IRC') unless $opt;
}

my $ver = sprintf('%vd',$^V);

my ($minstall,$mupdate);

{
  if ( -e 'minstall.sh' ) {
    open my $file, '<', 'minstall.sh' or die "$!\n";
    $minstall = grep { m!\Q$prefix\E! } <$file>;
    close $file;
  }

  if ( -e 'mupdate.sh' ) {
    open my $file, '<', 'mupdate.sh' or die "$!\n";
    $mupdate = grep { m!\Q$prefix\E! } <$file>;
    close $file;
  }
}

unless ( $minstall ) {
  # minstall.sh
  my $mode = ( -e 'minstall.sh' ? '>>' : '>' );
  open my $file, $mode, 'minstall.sh' or die "$!\n";
  print {$file} "PERL5_CPANPLUS_HOME=$prefix $^X tools/installer.pl \$*\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', 'authors', '*' ) . "\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', $ver ) . "\n";
  close $file;
  chmod 0755, 'minstall.sh';
}
unless ( $mupdate ) {
  # mupdate.sh
  my $mode = ( -e 'mupdate.sh' ? '>>' : '>' );
  open my $file, $mode, 'mupdate.sh' or die "$!\n";
  print {$file} "PERL5_CPANPLUS_HOME=$prefix $^X tools/updater.pl --all \$*\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', 'authors', '*' ) . "\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', $ver ) . "\n";
  close $file;
  chmod 0755, 'mupdate.sh';
}
