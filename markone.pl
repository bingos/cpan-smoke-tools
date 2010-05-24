use strict;
use warnings;
use CPANPLUS::Configure;
use POSIX qw( O_CREAT O_RDWR O_RDONLY );
use File::Spec::Functions;
use SDBM_File;

use constant DATABASE_FILE => 'cpansmoke.dat';

my %Checked;
my $TiedObj;

my $conf = CPANPLUS::Configure->new();

my $filename = catfile( $conf->get_conf('base'), DATABASE_FILE );
$TiedObj = tie %Checked, 'SDBM_File', $filename, O_CREAT|O_RDWR, 0644;

$Checked{ 'URI-1.54' } = 'pass';

$TiedObj = undef;
untie %Checked;
