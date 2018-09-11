#!/usr/bin/env perl

use strict;
use warnings;
use Env;

use File::Spec;
use lib File::Spec->catdir( substr( $DOCUMENT_ROOT, 0, rindex( $DOCUMENT_ROOT, '/')  ), 'cgi-lib');

use JSON::MaybeXS;
use CGI::Compress::Gzip;

# =================
# = PREPROCESSING =
# =================


# ============
# = RESPONSE =
# ============
my $cgi = CGI::Compress::Gzip->new();