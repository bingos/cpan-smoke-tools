#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Capture::Tiny qw(capture_merged);
use Config;
use Cwd;
use Getopt::Long;

my $recent;
my $reverse;
my $path;

GetOptions('recent' => \$recent, 'reverse' => \$reverse, 'path=s', \$path);

die "No path option specified\n" unless $path and -d $path;

open my $script, '>', 'smokeall.sh' or die "$!\n";

print $script '#!/bin/sh', "\n";

my @authors = (
  '^A[N-Z]',
  '^B[A-M]',
  '^B[N-Z]',
  '^C',
  '^D[A-M]',
  '^D[N-Z]',
  '^[EF]',
  '^G',
  '^[HI]',
  '^J[A-M]',
  '^J[N-Z]',
  '^K',
  '^L',
  '^M[A-M]',
  '^M[N-Z]',
  '^[NO]',
  '^[PQ]',
  '^R[A-M]',
  '^R[N-Z]',
  '^S[A-M]',
  '^S[N-Z]',
  '^T',
  '^[UVWXY]',
  '^Z',
);

my $minismokebox = File::Spec->catfile($Config::Config{installsitescript},'minismokebox');
die "No 'minismokebox' found\n" unless $minismokebox;
my $perl = File::Spec->catfile($path,'bin','perl');
my $yactool = File::Spec->catfile($path,'bin','yactool');
unless ( -e $perl ) {
  # hmmm no perl there. Let's see if it is a dev release
  my @possibles = glob("${perl}5*");
  die "No perl executable found at '$path'\n" unless @possibles;
  $perl = shift @possibles;
}
my $output = capture_merged { system($perl,'-e','printf "%vd", $^V;'); };
chomp $output;
my $cpanp = File::Spec->catfile($path,'bin', 'cpanp' . ( $perl =~ /\Q$output\E$/ ? $output : '' ) );

print $script qq{$minismokebox --perl $perl\n} if $recent;

foreach my $author ( @authors ) {
  #print $script qq{perl -MFile::Path -e 'rmtree shift;' $conf\n};
  print $script qq{$yactool --flush\n};
  print $script qq{$cpanp -x --update_source\n};
  print $script qq{$minismokebox --perl $perl --author '$author'\n};
}
print $script qq{perl -MFile::Path -e 'rmtree shift;' $conf\n};

close $script;
chmod 0755, 'smokeall.sh' or die "$!\n";
exit 0;

__END__

=head1 NAME

genscript.pl - Generate a shell script to smoke all of CPAN

=head1 SYNOPSIS

  perl genscript.pl --path /path/to/perl/installation

=head1 DESCRIPTION

genscript.pl is a perl script that will generate a shell script that
can be used to smoke test all of CPAN using L<minismokebox>

=head1 CONFIGURATION

The script will locate the L<minismokebox> that is associated with the C<perl>
that was used to execute the script and use that in the generated script.

The value of the C<%ENV> variable C<PERL5_YACSMOKE_BASE> is used to find the 
location of the C<.cpanplus> folder which requires cleaning up.

The C<--path> command-line switch is used to find the C<perl> executable to 
use to do the smoke testing with.

  Example: perl-5.10.1 has been built and installed with Dprefix=/home/cpan/perl-5.10.1

  perl genscript.pl --path /home/cpan/perl-5.10.1

=head1 SWITCHES

=over

=item C<--path>

The path to the C<perl> installation to smoke test with. Usually what was passed to
C<Configure> at build time with C<Dprefix>.

=item C<--recent>

Indicate whether you want to smoke test recent uploads to CPAN before smoke testing all
of CPAN.

=item OUTPUT

The script generates a shell script in the current working directory called C<smokeall.sh>

This can be simply invoked 

  ./smokeall.sh

to start the (lengthy) CPAN smoke process. >:)

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=cut
