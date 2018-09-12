package Drone::Worker;

use v5.16;

use LWP::UserAgent::Cached;
use LWP::ConnCache;
use HTTP::Message;

use String::Truncate;

use Mustache::Simple;
use Digest::SHA qw(sha256_hex);

use JSON::MaybeXS;
use Data::Dump qw/dd/;



use constant {
    HTTP => 0,
    TEMPLATE => 1,
    HELPERS => 2,
    DATAMAP => 3
};


sub new {
    my ( $class, $args ) = ( shift, { @_ } );
    
    # set up the client stack
    my $http = LWP::UserAgent::Cached->new(
        cache_dir => ( $args->{'cache_dir'} )  ?   $args->{'cache_dir'}  : '.cache',
		agent => ( $args->{'agent'} ) ? $args->{'agent'} : 'Beelabs Drone WebCrawler  (v1.02 RC)',
		timeout => 10,
		ssl_opts => { verify_hostname => 0 },
		conn_cache => LWP::ConnCache->new()
    );
    
    my $helpers = {
        '@uppercase' => sub { return uc( shift ) },
        '@lowercase' => sub { return lc( shift ) } 
    };
    
    my $stache = Mustache::Simple->new();
    
    
    return bless ([
        $http, # httpclient
        $stache,
        $helpers
    ], $class);
}


sub get
{
    my ( $self, $url, $nocache ) = @_;
    
    my $res = $self->[HTTP]->get( $url, 'Accept-Encoding' => HTTP::Message::decodable );
    
    if ( $nocache )
    {
        $self->[HTTP]->uncache();
    }
    
    if ($res->is_success) {
        
        my $json = decode_json( $res->decoded_content );
        # lets add some properties 
        $json->{'drn_url'} = $res->request()->url->as_string;
        
        return $json
    }
    
    say "-"x80;
    say "   [Drone::Worker] http request error ...";
    say "       HTTP get code: ". $res->request()->url;
    say "       HTTP get code: ". $res->code;
    say "       HTTP get msg : ". $res->message;
    say "-"x80;
}

sub datamap
{
     my ( $self, $mapping ) = ( @_ );
     
     if ( $mapping )
     {
         $self->[DATAMAP] = $mapping;
     }
     
     $self->[DATAMAP];
}

sub transform
{
    my ( $self, $data, $overrides ) = ( @_ );
    
    my ( $map , $object ) = ( { %$self->[DATAMAP], %$overrides }, {} );
        
    foreach my $indx ( keys $map ) {
        say "indx -> $indx / ".$map->{$indx};
    }
    
    
}

sub _truncate
{
    my ( $self, $data ) = ( @_ );
    return String::Truncate::elide( $data, 225 );
}

sub _template
{
     my ( $self, $data ) = ( @_ );
}

sub _redirect
{
     my ( $self, $url ) = ( @_ );
}

sub _hash
{
    my ( $self, $data ) = ( @_ );
    return sha256_hex( $data );
}

sub _freeze
{
    my ( $self, $format ,$data ) = ( @_ );
    
    if ( $format eq 'json' )
    {
        return json_encode( $data );
    }
}

1;
