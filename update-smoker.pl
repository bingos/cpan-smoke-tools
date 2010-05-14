use strict;
use warnings;
use CPANPLUS::Configure;
use CPANPLUS::Backend;
my $conf = CPANPLUS::Configure->new();
$conf->set_conf( prereqs => 1 );
my $cb = CPANPLUS::Backend->new( $conf );
my $su = $cb->selfupdate_object;

$su->selfupdate( update => 'dependencies', latest => 1 );
$cb->module_tree( $_ )->install() for 
      qw(
          CPANPLUS
          File::Temp
          Compress::Raw::Bzip2
          Compress::Raw::Zlib
          Compress::Zlib
          ExtUtils::CBuilder
          ExtUtils::ParseXS
          ExtUtils::Manifest
          Module::Build
          CPANPLUS::YACSmoke
      );
$_->install() for map { $su->modules_for_feature( $_ ) } qw(prefer_makefile md5 storable cpantest);
