use strict;
use warnings;
BEGIN {
  use FindBin qw($Bin);
  use lib $Bin;
}
use CPANPLUS::Configure;
use CPANPLUS::Backend;
my $conf = CPANPLUS::Configure->new();
$conf->set_conf( cpantest => 0 );
$conf->set_conf( prereqs => 1 );
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
my $cb = CPANPLUS::Backend->new( $conf );
#$cb->reload_indices( update_source => 1 );
my $su = $cb->selfupdate_object;

$su->selfupdate( update => 'dependencies', latest => 1 );
$cb->module_tree( $_ )->install() for 
      qw(
          CPANPLUS
          File::Temp
          Compress::Raw::Bzip2
          Compress::Raw::Zlib
          Compress::Zlib
          ExtUtils::MakeMaker
          ExtUtils::CBuilder
          ExtUtils::ParseXS
          ExtUtils::Manifest
          Module::Build
          CPANPLUS::YACSmoke
          Test::Reporter::Transport::Socket
      );
$_->install() for map { $su->modules_for_feature( $_ ) } qw(prefer_makefile md5 storable cpantest);
