#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use File::Spec;
use lib File::Spec->catdir( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/')  ), 'cgi-lib');

use Path::Tiny qw/path/;
use JSON::MaybeXS;
use Drone::Worker;

use YAML::XS qw/LoadFile/;

use Data::Dmp qw/dd dmp/;


# =================
# = PREPROCESSING =
# =================
my $basedir = path( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/') ) );

$basedir->child('.cache')->absolute->mkpath if ( ! $basedir->child('.cache')->is_dir() );

my $worker = Drone::Worker->new( cache_dir => $basedir->child('.cache')->absolute->stringify );

my $config = LoadFile( path($0)->sibling('index.yaml')->stringify );

my @actions =  @{ $config->{actions} };

for (my $idx = 0; $idx < scalar @actions; $idx++) {
    my $actn = $actions[$idx];
    
    my @dataset = $worker->swarm( $actn );
    
    foreach my $record (@dataset) {
        say " [record] .. ".$record->{'id'}." / ".$record->{'title'};
    }
    
    
    #path('test.json')->spew_utf8( encode_json( \@dataset ) ) if ( $idx == 0 );
    
    exit;
   #say " processing :: ". $actn->{urls}->[0]->{url};
}



#$worker->datamap( $config->{actions} )

#dd $worker->get('http://healthycanadians.gc.ca/recall-alert-rappel-avis/api/search?search=&lang=en&cat=1&lim=5&off=0', 1);



# ============
# = RESPONSE =
# ============