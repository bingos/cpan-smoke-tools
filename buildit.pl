use strict;
use warnings;
use File::Spec;
use Config;
use IPC::Cmd qw[can_run];
use Cwd;

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

foreach my $type ( @types ) {
  print $script "$smokebrew --prefix ",
    join(' ', File::Spec->catdir( $root, $type ), @{ $choices->{ $type } } ), "\n";
}

close $script;
chmod 0755, 'build.it' or die "$!\n";
exit 0;
