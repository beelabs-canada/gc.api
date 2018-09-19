package APIx::Util::HttpClient;

use base 'Class::Singleton';

use common::sense;
use v5.16;

use LWP::UserAgent::Cached;
use LWP::ConnCache;
use HTTP::Message;
use URI;


use constant {
    UA => 0,
    CONFIG => 1
};

sub _new_instance {
    my ( $class, $args ) = ( shift, { @_ } );
    
    my $http = LWP::UserAgent::Cached->new(
        cache_dir => $args->{'cache_dir'},
		agent => ( $args->{'agent'} ) ? $args->{'agent'} : 'APIx WebCrawler  (v1.02 RC)',
		timeout => 10,
		ssl_opts => { verify_hostname => 0 },
		conn_cache => LWP::ConnCache->new()
    );
    
    my $config = {
         cache_dir => ( $args->{'cache_dir'} )  ?   $args->{'cache_dir'}  : '.cache'
    };
    
    return bless [ $http, $config ], $class ;
}

sub get
{
    my ( $self, $url, $body, $nocache ) = @_;
    
    say " [__PACKAGE__] get : $url";
    
    my $res = $self->[UA]->get( $url, 'Accept-Encoding' => HTTP::Message::decodable );
    
    if ( $nocache )
    {
        $self->[UA]->uncache();
    }
    
    if ($res->is_success) {
        
        my $json = decode_json( $res->decoded_content );
        
        if ( $body )
        {
            $json = $json->{ $body  };
        }
        
        if ( ref($json) eq "HASH" )
        {
            # lets add some properties if an object
            $json->{'apix:url'} = $res->request()->url->as_string;
        }
        
        return $json
    }
    
    say "-"x80;
    say "   [__PACKAGE__] http request error ...";
    say "       HTTP get code: ". $res->request()->url;
    say "       HTTP get code: ". $res->code;
    say "       HTTP get msg : ". $res->message;
    say "-"x80;
    
    return ;
}

sub download
{
    my ($self, $url ) = @_;
    
    my $bname = pop (URI->new($url)->path_segments);
    
    $self->[UA]->get( $url, ':content_file' => $bname );
    
    # lets not cache any assets
    $self->[UA]->uncache();
    
    return $bname;
}

1;
