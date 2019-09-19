use strict;
use warnings;
use File::Spec;
use Config;
use IPC::Cmd qw[can_run];
use Getopt::Long;
use Cwd;

my $compiler = '';
my $ld;
my $qm;
my $latest = '';

GetOptions( 'cc=s', \$compiler, 'ld', \$ld, 'latest', \$latest, 'qm', \$qm );
$compiler = '' unless can_run( $compiler );

my $smokebrew = File::Spec->catfile($Config::Config{installsitescript},'smokebrew');
die "No 'smokebrew' found\n" unless $smokebrew;

my $root = shift || Cwd::cwd();
$root = Cwd::abs_path( $root );

my $shell;

$shell = can_run('bash');
$shell = can_run('sh') unless $shell;
$shell = '/bin/sh' unless $shell;

open my $script, '>', 'build.it' or die "$!\n";
print $script "#!$shell", "\n";

my $choices = {
  'bare'  => [ ],
  'thr'   => [ '--perlargs', '"-Dusethreads"' ],
  'rel'   => [ '--perlargs', '"-Dusethreads"', '--perlargs', '"-Duse64bitint"' ],
  '64bit' => [ '--perlargs', '"-Duse64bitint"' ],
};

my @types = ( 'bare', 'thr' );
push @types, ( 'rel', '64bit' ) unless $Config::Config{use64bitall};

if ( $ld ) {
  foreach my $type ( keys %{ $choices } ) {
    $choices->{ $type . '-ld' } = [ @{ $choices->{ $type } }, '--perlargs', '"-Duselongdouble"' ];
  }
  push @types, ( 'bare-ld', 'thr-ld' );
  push @types, ( 'rel-ld', '64bit-ld' ) unless $Config::Config{use64bitall};
}

if ( $qm ) {
  foreach my $type ( grep { ! m!\-ld$! } keys %{ $choices } ) {
    $choices->{ $type . '-qm' } = [ @{ $choices->{ $type } }, '--perlargs', '"-Dusequadmath"' ];
  }
  push @types, ( 'bare-qm', 'thr-qm' );
  push @types, ( 'rel-qm', '64bit-qm' ) unless $Config::Config{use64bitall};
}

foreach my $type ( @types ) {
  print $script "$smokebrew --prefix ",
    join(' ',
      File::Spec->catdir( $root, $type ),
      @{ $choices->{ $type } },
      ( $compiler ? qq{--perlargs "-Dcc=$compiler"} : () ),
      ( $latest   ? qq{--latest} : () ),
    ), "\n";
}

close $script;
chmod 0755, 'build.it' or die "$!\n";
exit 0;
