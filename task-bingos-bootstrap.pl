use strict;
use warnings;
if ( $^O eq 'cygwin' ) {
  exec "wget --no-check-certificate -O - http://cpanmin.us | $^X - -v --no-curl --without-recommends --mirror http://cpan.mirror.local/CPAN/ --mirror-only Task::BINGOS::Bootstrap";
}
else {
  exec "curl -kL http://cpanmin.us | $^X - -v --without-recommends --mirror http://cpan.mirror.local/CPAN/ --mirror-only Task::BINGOS::Bootstrap";
}
