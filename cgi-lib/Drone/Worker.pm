package Drone::Worker;

use v5.16;

use LWP::UserAgent::Cached;
use LWP::ConnCache;
use HTTP::Message;

use String::Truncate;

use Mustache::Simple;
use Digest::SHA qw(sha256_hex);

use Scalar::Util qw/looks_like_number/;
use JSON::MaybeXS;
use Data::Dmp qw/dd dmp/;



use constant {
    HTTP => 0,
    STACHE => 1,
    HELPERS => 2
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
    my ( $self, $url, $body, $nocache ) = @_;
    
    say " [get] $url";
    
    my $res = $self->[HTTP]->get( $url, 'Accept-Encoding' => HTTP::Message::decodable );
    
    if ( $nocache )
    {
        $self->[HTTP]->uncache();
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


sub swarm
{
    my ( $self, $action ) = ( @_ );
    
    my $datamap = delete $action->{'mapping'};
    my @resources = @{ delete $action->{urls} };
    
    my @results = ();
    
    foreach my $resource ( @resources ) {
        # step one lets get the url to action
        my $url = delete $resource->{url};
        
        $action = { %$action, %{$resource} };
           
        my $json = $self->get( $url, $action->{'body'} );
        
        if ( ref( $json ) ne 'ARRAY' )
        {
            push ( @results, $self->datamap( $action, $datamap, $json ) );
            next;
        }
        
        push( @results, $self->datamap( $action, $datamap, $_ ) ) for (@$json);
        
    }
    return @results;
}

sub datamap
{
     my ( $self, $action, $map, $data  ) = ( @_ );
          
     if ( $action->{'redirect'} )
     {
        
        my $surl = $self->_template( $action->{'redirect'}, $data );
          
        $data = $self->get( $surl );
     }
     
     return $self->transform( $data, $map );

}

sub transform
{
    my ( $self, $data, $map ) = ( @_ );
    
    my $object = {};
        
    foreach my $idx ( keys $map ) {
		
		if ( $idx eq 'data:freeze' )
		{
			$object->{'data'} = $self->_freeze( $data ) ;
			next;
		}
        
        my @action = split(/\:/, $idx );
		
		my $field = shift( @action );
				
		my @param = ( ref ( $map->{$idx} ) eq 'ARRAY' ) ? @{ $map->{$idx} }[0] : ( $map->{$idx} ) ;
		
		my $value = $self->_dottags( shift( @param ) , $data );
				
		if ( @action )
		{
			my $func = '_'.$action[0];
			$value = $self->$func( @param , $value )
		}
		        
        $object->{$field} = $value ;
    }
    
    return $object;
}

sub _truncate
{
    my ( $self, $data ) = ( @_ );
    return String::Truncate::elide( $data, 225 );
}

sub _template
{
     my ( $self, $template, $data ) = ( @_ );
     
     $data = { %{$data}, %{ $self->[HELPERS] } };

     return $self->[STACHE]->render( $template, $data );
}

sub _regex
{
	my ( $self, $regex, $data ) = ( @_ );
	
	#dd $regex;
	
	my @results = ( $data =~ m/$regex/ );
	
	#dd @results;
	
	return @results;
	
}

sub _dottags {
	my ( $self, $notation, $data ) = ( @_ );
	
	return '' unless ( $notation );

	
	foreach my $idx ( split /\./, $notation )
	{
		if ( looks_like_number( $idx ) )
		{
			# this is number so lets assume it works
			
			if ( ref( $data ) eq 'ARRAY' and scalar( $data ) <= $idx )
			{
				$data = $data->[$idx];
				next;
			}
		
			return '';
		}
		
		if ( ! exists $data->{ $idx } )
		{
			return '';
		}
		
		$data = $data->{ $idx };
	}
	
	return $data;
}


sub _hash
{
    my ( $self, $data ) = ( @_ );
	
    return sha256_hex( $data );
}

sub _freeze
{
    my ( $self, $data ) = ( @_ );
    
   return encode_json( $data );
    
}

1;
