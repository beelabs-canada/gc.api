#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use File::Spec;
use lib File::Spec->catdir( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/')  ), 'cgi-lib');

use Path::Tiny qw/path/;

use JSON::MaybeXS;

use DBI;
use SQL::Abstract;
use APIx::Store;

use YAML::XS qw/LoadFile/;


binmode STDOUT, ":encoding(UTF-8)";


# =================
# = PREPROCESSING =
# =================
my ( $basedir, $sql, $config ) = ( 
        path( substr( File::Spec->rel2abs($0), 0, index( File::Spec->rel2abs($0), '/public/') ) ),
        SQL::Abstract->new(),
        LoadFile( path($0)->sibling('index.yaml')->absolute->stringify )
);

my $dbname = $basedir->child( $config->{'database'}->{'path'} )->stringify;

$basedir->child('.cache')->absolute->mkpath if ( ! $basedir->child('.cache')->is_dir() );

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbname", '','' , {
   PrintError       => 1,
   RaiseError       => 1,
   AutoCommit       => 1
});


my $store = APIx::Store->new( config =>  $config );

# ============
# = RESPONSE =
# ============