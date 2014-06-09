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

push @INC, sub {
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
use File::Spec;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Configure;
use CPANPLUS::Backend;
use Config::Tiny;
use Getopt::Long;

my $host = '';
my $cpanidx = '';
my $mirror = '';

CONFIG: {
  my $file = _get_config_file();
  last CONFIG unless $file and -e $file;
  my $conf = Config::Tiny->new()->read( $file );
  last CONFIG unless $conf;
  $mirror  = $conf->{_}->{mirror};
  $host    = $conf->{_}->{relay};
  $cpanidx = $conf->{_}->{cpanidx};
}

my $test = '';
my $uninstall = '';

GetOptions( 'test' => \$test, 'uninstall' => \$uninstall );

$ENV{PERL5_CPANIDX_URL} = $cpanidx if $cpanidx;
$ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';
$ENV{PERL_INSTALL_QUIET} = 1; #stfu

exit 0 unless @ARGV;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
$conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' )
  if check_install( module => 'CPANPLUS::Dist::YACSmoke' ) and !$uninstall;
$conf->set_conf( 'prereqs' => 2 );
$conf->set_conf( 'prefer_bin' => 1 );
$conf->set_conf( prefer_makefile => 0 );
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
foreach my $mod ( @ARGV ) {
  my $module = $cb->parse_module( module => $mod );
  next unless $module;
  if ( $uninstall ) {
    $module->uninstall();
  }
  else {
    $module->install( ( $test ? ( target => 'create' ) : () ) );
  }
}
exit 0;

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

