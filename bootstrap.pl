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
