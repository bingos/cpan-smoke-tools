use strict;
use warnings;
exec "curl -kL http://cpanmin.us | $^X - -v --mirror http://cpan.mirror.local/CPAN/ --mirror-only Task::BINGOS::Bootstrap";