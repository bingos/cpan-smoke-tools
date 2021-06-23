use strict;
use warnings;
use File::Path qw[rmtree];
use File::Spec;

my $tmpdir = File::Spec->tmpdir;
my $name   = 'cpan';
my $uid    = getpwnam($name);
my $now    = time();

{
  opendir( my $TMPDIR, $tmpdir ) or die "$!\n";
  while (my $item = readdir($TMPDIR)) {
    next if $item =~ /^\.{1,2}$/;
    next if $item eq 'uscreens';
    next if $item =~ m!^tmux!;
    my $file = File::Spec->catfile($tmpdir,$item);
    my ($fuid,$mtime);
    if ( -l $file ) {
      ($fuid,$mtime) =  ( lstat($file) )[4,9];
    }
    else {
      ($fuid,$mtime) =  ( stat($file) )[4,9];
    }
    next unless $uid == $fuid; # and $now - $mtime > 86400;
    print $file, "\n";
    rmtree( $file );
  }
}
