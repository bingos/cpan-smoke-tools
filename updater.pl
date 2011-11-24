# This chunk of stuff was generated by App::FatPacker. To find the original
# file's code, look for the end of this BEGIN block or the string 'FATPACK'
BEGIN {
my %fatpacked;

$fatpacked{"Config/Tiny.pm"} = <<'CONFIG_TINY';
	package Config::Tiny;
	# If you thought Config::Simple was small...
	use strict;
	BEGIN {
		require 5.004;
		$Config::Tiny::VERSION = '2.14';
		$Config::Tiny::errstr  = '';
	}
	# Create an empty object
	sub new { bless {}, shift }
	# Create an object from a file
	sub read {
		my $class = ref $_[0] ? ref shift : shift;
		# Check the file
		my $file = shift or return $class->_error( 'You did not specify a file name' );
		return $class->_error( "File '$file' does not exist" )              unless -e $file;
		return $class->_error( "'$file' is a directory, not a file" )       unless -f _;
		return $class->_error( "Insufficient permissions to read '$file'" ) unless -r _;
		# Slurp in the file
		local $/ = undef;
		open( CFG, $file ) or return $class->_error( "Failed to open file '$file': $!" );
		my $contents = <CFG>;
		close( CFG );
		$class->read_string( $contents );
	}
	# Create an object from a string
	sub read_string {
		my $class = ref $_[0] ? ref shift : shift;
		my $self  = bless {}, $class;
		return undef unless defined $_[0];
		# Parse the file
		my $ns      = '_';
		my $counter = 0;
		foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift ) {
			$counter++;
			# Skip comments and empty lines
			next if /^\s*(?:\#|\;|$)/;
			# Remove inline comments
			s/\s\;\s.+$//g;
			# Handle section headers
			if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
				# Create the sub-hash if it doesn't exist.
				# Without this sections without keys will not
				# appear at all in the completed struct.
				$self->{$ns = $1} ||= {};
				next;
			}
			# Handle properties
			if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
				$self->{$ns}->{$1} = $2;
				next;
			}
			return $self->_error( "Syntax error at line $counter: '$_'" );
		}
		$self;
	}
	# Save an object to a file
	sub write {
		my $self = shift;
		my $file = shift or return $self->_error(
			'No file name provided'
			);
		# Write it to the file
		my $string = $self->write_string;
		return undef unless defined $string;
		open( CFG, '>' . $file ) or return $self->_error(
			"Failed to open file '$file' for writing: $!"
			);
		print CFG $string;
		close CFG;
	}
	# Save an object to a string
	sub write_string {
		my $self = shift;
		my $contents = '';
		foreach my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self ) {
			# Check for several known-bad situations with the section
			# 1. Leading whitespace
			# 2. Trailing whitespace
			# 3. Newlines in section name
			return $self->_error(
				"Illegal whitespace in section name '$section'"
			) if $section =~ /(?:^\s|\n|\s$)/s;
			my $block = $self->{$section};
			$contents .= "\n" if length $contents;
			$contents .= "[$section]\n" unless $section eq '_';
			foreach my $property ( sort keys %$block ) {
				return $self->_error(
					"Illegal newlines in property '$section.$property'"
				) if $block->{$property} =~ /(?:\012|\015)/s;
				$contents .= "$property=$block->{$property}\n";
			}
		}
		$contents;
	}
	# Error handling
	sub errstr { $Config::Tiny::errstr }
	sub _error { $Config::Tiny::errstr = $_[1]; undef }
	1;
CONFIG_TINY

s/^  //mg for values %fatpacked;

unshift @INC, sub {
  if (my $fat = $fatpacked{$_[1]}) {
    open my $fh, '<', \$fat
      or die "FatPacker error loading $_[1] (could be a perl installation issue?)";
    return $fh;
  }
  return
};

} # END OF FATPACK CODE

use strict;
use warnings;
use Term::UI;
use Term::ReadLine;
use ExtUtils::Installed;
use File::Spec;
use File::Fetch;
use IO::Zlib;
use version;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Internals::Constants;
use CPANPLUS::Backend;
use CPANPLUS::Error;
use Getopt::Long;
use Config::Tiny;

$|=1;

my $host = '';
my $mirror = '';
my $cpanidx = '';

CONFIG: {
  my $file = _get_config_file();
  last CONFIG unless $file and -e $file;
  my $conf = Config::Tiny->new()->read( $file );
  last CONFIG unless $conf;
  $mirror  = $conf->{_}->{mirror};
  $host    = $conf->{_}->{relay};
  $cpanidx = $conf->{_}->{cpanidx};
}

$ENV{PERL5_CPANIDX_URL} = $cpanidx if $cpanidx;
$ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

my %installed;
my %cpan;
my %skip;
my $printonly;
my $all;

GetOptions( 'all', \$all, 'print', \$printonly );

$Term::UI::AUTOREPLY = 1 if $all;

if ( -e 'skiplist' ) {
  open my $skip, '<', 'skiplist' or die "Could not open skiplist: $!\n";
  while( <$skip> ) {
    chomp;
    my ($vers,$path) = split /\s+/;
    next unless $vers eq $];
    $skip{ $path }++;
  }
}

foreach my $module ( _all_installed() ) {
  my $href = check_install( module => $module );
  next unless $href;
  $installed{ $module } = defined $href->{version} ? $href->{version} : 'undef';
}

my $loc = fetch_indexes('.', ( $mirror || 'http://www.cpan.org/' ) ) or die;
populate_cpan( $loc );
my %seen;
foreach my $module ( sort keys %installed ) {
  # Eliminate core modules
  if ( supplied_with_core( $module ) and !$cpan{ $module } ) {
    delete $installed{ $module };
    next;
  }
  if ( !$cpan{ $module } ) {
    delete $installed{ $module };
    next;
  }
  if ( $module =~ /^Bundle::/ ) {
    delete $installed{ $module };
    next;
  }
  if ( $seen{ $cpan{ $module }->[1] } ) {
    delete $installed{ $module };
    next;
  }
  $seen{ $cpan{ $module }->[1] }++;
  unless ( _vcmp( $cpan{ $module }->[0], $installed{ $module} ) > 0 ) {
    delete $installed{ $module };
    next;
  }
  if ( $cpan{ $module }->[1] and $cpan{ $module }->[1] =~ m{\w/\w{2}/\w+/perl-\S+tar\.gz$}i ) {
    delete $installed{ $module };
    next;
  }
}

# Further eliminate choices.

my $term = Term::ReadLine->new('brand');

foreach my $module ( sort keys %installed ) {
  my $package = $cpan{ $module }->[1];
  if ( $skip{ $package } ) {
    delete $installed{ $module };
    next;
  }
  if ( $printonly ) {
    print $package, "\n";
    next;
  }
  unless ( $term->ask_yn(
               prompt => "Update package '$package' for '$module' ?",
               default => 'y',
  ) ) {
    delete $installed{ $module };
    if ( $term->ask_yn( prompt => 'Do you wish to permanently skip this package ?', default => 'n' ) ) {
      open my $skip, '>>', 'skiplist' or die "Could not open skiplist: $!\n";
      print $skip join(' ', $], $package), "\n";
    }
  }
}

exit 0 if $printonly;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
$conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' )
  if check_install( module => 'CPANPLUS::Dist::YACSmoke' );
$conf->set_conf( 'prereqs' => 2 );
$conf->set_conf( prefer_bin => 1 );
$conf->set_conf( 'cpantest_reporter_args' =>
    {
      transport       => 'Socket',
      transport_args  => [ host => $host, port => 8080 ],
    },
  )
  if $host && check_install( module => 'Test::Reporter::Transport::Socket' );
if ( $mirror ) {
  my $hosts = $conf->get_conf( 'hosts' );
  my @parts = $mirror =~ m!^(\w*)://([^/]*)(/.*)$!s;
  my $href;
  for my $key (qw[scheme host path]) {
    $href->{$key} = shift @parts;
  }
  unshift @$hosts, $href;
  $conf->set_conf( hosts => $hosts );
}
my $cb = CPANPLUS::Backend->new($conf);
foreach my $mod ( sort keys %installed ) {
  my $module = $cb->module_tree($mod);
  next unless $module;
  CPANPLUS::Error->flush();
  $module->install();
}
exit 0;

sub supplied_with_core {
  my $name = shift;
  my $ver = shift || $];
  require Module::CoreList;
  return $Module::CoreList::version{ 0+$ver }->{ $name };
}

sub _vcmp {
  my ($x, $y) = @_;
  s/_//g foreach $x, $y;
  return version->parse($x) <=> version->parse($y);
}

sub populate_cpan {
  my $pfile = shift;
  my $fh = IO::Zlib->new( $pfile, "rb" ) or die "$!\n";
  my %dists;

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    $cpan{ $module } = [ $version, $package_path ];
  }
  return 1;
}

sub fetch_indexes {
  my ($location,$mirror) = @_;
  my $packages = 'modules/02packages.details.txt.gz';
  my $url = join '', $mirror, $packages;
  my $ff = File::Fetch->new( uri => $url );
  my $stat = $ff->fetch( to => $location );
  return unless $stat;
  print "Downloaded '$url' to '$stat'\n";
  return $stat;
}

sub _all_installed {
    ### File::Find uses follow_skip => 1 by default, which doesn't die
    ### on duplicates, unless they are directories or symlinks.
    ### Ticket #29796 shows this code dying on Alien::WxWidgets,
    ### which uses symlinks.
    ### File::Find doc says to use follow_skip => 2 to ignore duplicates
    ### so this will stop it from dying.
    my %find_args = ( follow_skip => 2 );

    ### File::Find uses lstat, which quietly becomes stat on win32
    ### it then uses -l _ which is not allowed by the statbuffer because
    ### you did a stat, not an lstat (duh!). so don't tell win32 to
    ### follow symlinks, as that will break badly
    $find_args{'follow_fast'} = 1 unless ON_WIN32;

    ### never use the @INC hooks to find installed versions of
    ### modules -- they're just there in case they're not on the
    ### perl install, but the user shouldn't trust them for *other*
    ### modules!
    ### XXX CPANPLUS::inc is now obsolete, remove the calls
    #local @INC = CPANPLUS::inc->original_inc;

    my %seen; my @rv;
    for my $dir (@INC ) {
        next if $dir eq '.';

        ### not a directory after all
        ### may be coderef or some such
        next unless -d $dir;

        ### make sure to clean up the directories just in case,
        ### as we're making assumptions about the length
        ### This solves rt.cpan issue #19738

        ### John M. notes: On VMS cannonpath can not currently handle
        ### the $dir values that are in UNIX format.
        $dir = File::Spec->canonpath( $dir ) unless ON_VMS;

        ### have to use F::S::Unix on VMS, or things will break
        my $file_spec = ON_VMS ? 'File::Spec::Unix' : 'File::Spec';

        ### XXX in some cases File::Find can actually die!
        ### so be safe and wrap it in an eval.
        eval { File::Find::find(
            {   %find_args,
                wanted      => sub {

                    return unless /\.pm$/i;
                    my $mod = $File::Find::name;

                    ### make sure it's in Unix format, as it
                    ### may be in VMS format on VMS;
                    $mod = VMS::Filespec::unixify( $mod ) if ON_VMS;

                    $mod = substr($mod, length($dir) + 1, -3);
                    $mod = join '::', $file_spec->splitdir($mod);

                    return if $seen{$mod}++;

                    push @rv, $mod;
                },
            }, $dir
        ) };

    }

    return @rv;
}

sub _get_config_file {
  my $base = glob('~');
  if ( $base eq '~' and $^O eq 'MSWin32' ) {
      $base = File::Spec->catdir( $ENV{APPDATA}, 'cpanpq' );
  }
  else {
     $base = File::Spec->catfile( $base, '.cpanpq' );
  }
  return $base;
}

