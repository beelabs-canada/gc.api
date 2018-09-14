#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use File::Spec;
use lib File::Spec->catdir( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/')  ), 'cgi-lib');

use Path::Tiny qw/path/;
use JSON::MaybeXS;
use Drone::Worker;

use DBI;
use SQL::Abstract;

use YAML::XS qw/LoadFile/;

use Data::Dmp qw/dd dmp/;

binmode STDOUT, ":encoding(UTF-8)";


# =================
# = PREPROCESSING =
# =================
my ( $basedir, $sql ) = ( 
        path( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/') ) ),
        SQL::Abstract->new()
    );

$basedir->child('.cache')->absolute->mkpath if ( ! $basedir->child('.cache')->is_dir() );


my $dbh = DBI->connect( "dbi:SQLite:dbname=".$basedir->child('db/rsa/database.sqlite')->stringify , '','' , {
   PrintError       => 1,
   RaiseError       => 1,
   AutoCommit       => 1
});

my $worker = Drone::Worker->new( cache_dir => $basedir->child('.cache')->absolute->stringify );

my $config = LoadFile( path($0)->sibling('index.yaml')->stringify );

my @actions =  @{ $config->{actions} };

for (my $idx = 0; $idx < scalar @actions; $idx++) {
    my $actn = $actions[$idx];
    
    $worker->swarm( $actn, 'recalls', $dbh );
    
    # foreach my $record (@dataset)
 #    {
 #
 #
 #       my ($stmt, @bind) = $sql->insert( 'recalls', $record );
 #
 #       my $sth = $dbh->prepare($stmt);
 #
 #       $sth->execute(@bind);
 #
 #       $sth->finish();
 #
 #       say " [inserted] recall : ".$record->{ url };
 #    }
    
}

# ============
# = RESPONSE =
# ============