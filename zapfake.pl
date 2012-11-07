use strict;
use warnings;
use File::Path qw[rmtree];
use File::Spec;

my $tmpdir = shift or die;
die unless -d $tmpdir;
my $name   = 'cpan';
my $uid    = getpwnam($name);
my $now    = time();

{
  opendir( my $TMPDIR, $tmpdir ) or die "$!\n";
  while (my $item = readdir($TMPDIR)) {
    next if $item =~ /^\.{1,2}$/;
    my $file = File::Spec->catfile($tmpdir,$item);
    my ($fuid,$mtime) = ( stat($file) )[4,9];
    next unless $uid == $fuid; # and $now - $mtime > 86400;
    print $file, "\n";
    rmtree( $file );
  }
}
