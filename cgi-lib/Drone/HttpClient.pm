package Drone::HttpClient;


use strict;
use warnings;
use v5.16;

use LWP::UserAgent::Cached;
use LWP::ConnCache;
use HTTP::Message;
use Path::Tiny;

use constant UA => 0;

sub new {
    my ( $class $args ) = ( shift, { @_ } );
    
    my $http = LWP::UserAgent::Cached->new(
        cache_dir => ( $args->{'cache_dir'} )  ?   $args->{'cache_dir'}  : '.cache',
		agent => ( $args->{'agent'} ) ? $args->{'agent'} : 'Beelabs Drone WebCrawler  (v1.02 RC)',
		timeout => 10,
		ssl_opts => { verify_hostname => 0 },
		conn_cache => LWP::ConnCache->new()
    );
    
    return bless [
        $http
    ], $class;
}

sub get
{
    my ( $self, $url, $body, $nocache ) = @_;
    
    say " [get] $url";
    
    my $res = $self->[UA]->get( $url, 'Accept-Encoding' => HTTP::Message::decodable );
    
    if ( $nocache )
    {
        $self->[UA]->uncache();
    }
    
    if ($res->is_success) {
        
        my $json = decode_json( $res->decoded_content );
        
        if ( $body )
        {
            $json = $json->{$body};
        }
        
        if ( ref($json) eq "HASH" )
        {
            # lets add some properties if an object
            $json->{'drn_url'} = $res->request()->url->as_string;
        }
        
        return $json
    }
    
    say "-"x80;
    say "   [Drone::Worker] http request error ...";
    say "       HTTP get code: ". $res->request()->url;
    say "       HTTP get code: ". $res->code;
    say "       HTTP get msg : ". $res->message;
    say "-"x80;
    
    return ;
}

sub download
{
    my ($self, $url ) = @_;
    
    my $bname = basename( $url );
    
    $self->[UA]->get( $url, ':content_file' => $bname );
    
    # lets not cache any assets
    $self->[UA]->uncache();
    
    return Path::Tiny->path( $0 )->sibling( $bname );
}

1;
