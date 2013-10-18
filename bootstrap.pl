use strict;
use warnings;
use File::Spec;
use Config;

my $prefix = $Config::Config{prefix};
{
  local $ENV{APPDATA} = $prefix;
  system($^X, 'tools/cpconf.pl');
  system($^X, 'tools/updater.pl', '--all');
  system($^X, 'tools/installer.pl', 'List::UtilsBy');
  system($^X, 'tools/installer.pl', 'App::SmokeBrew::Plugin::BINGOS');
  system($^X, 'tools/installer.pl', 'App::SmokeBox::Mini::Plugin::IRC');
}

my $ver = sprintf('%vd',$^V);

{
  # minstall.sh
  my $mode = ( -e 'minstall.sh' ? '>>' : '>' );
  open my $file, $mode, 'minstall.sh' or die "$!\n";
  print {$file} "PERL5_CPANPLUS_HOME=$prefix $^X tools/installer.pl \$*\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', 'authors', '*' ) . "\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', $ver ) . "\n";
  close $file;
}
{
  # mupdate.sh
  my $mode = ( -e 'mupdate.sh' ? '>>' : '>' );
  open my $file, $mode, 'mupdate.sh' or die "$!\n";
  print {$file} "PERL5_CPANPLUS_HOME=$prefix $^X tools/updater.pl --all\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', 'authors', '*' ) . "\n";
  print {$file} "rm -rf " . File::Spec->catdir( $prefix, '.cpanplus', $ver ) . "\n";
  close $file;
}
