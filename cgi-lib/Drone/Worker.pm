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
use Text::CSV;
use Data::Dmp qw/dd dmp/;

use Text::Trim;
use SQL::Abstract;


use constant {
    HTTP => 0,
    STACHE => 1,
    HELPERS => 2,
    CSV => 3,
    SQL => 4
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
    
    my $sql = SQL::Abstract->new();
    
    my $csv = Text::CSV->new();
    
    return bless ([
        $http, # httpclient
        $stache,
        $helpers,
        $csv,
        $sql
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
    my ( $self, $action, $table, $dbh ) = ( @_ );
    
    my $datamap = delete $action->{'mapping'};
    my @resources = @{ delete $action->{urls} };
    
    my @results = ();
    
    foreach my $resource ( @resources ) {
        # step one lets get the url to action
        my $url = delete $resource->{url};
        
        $action = { %$action, %{$resource} };
           
        my $json = $self->get( $url, $action->{'body'} );
        
        #{
        #    push ( @results, $self->datamap( $action, $datamap, $json ) );
        #    next;
        #}
        
        #push( @results, $self->datamap( $action, $datamap, $_ ) ) for (@$json);
        
        foreach my $item ( (ref( $json ) ne 'ARRAY' ) ? ( $json ) : @$json )
        {
            my ($stmt, @bind) = $self->[SQL]->insert( $table,  $self->datamap( $action, $datamap, $item ) );
            my $sth = $dbh->prepare($stmt);
            $sth->execute(@bind);
            $sth->finish();
            say " [inserted] recall : ".$item->{ url };
        }
        
        
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
     
     $map->{'_globals'} = $action;
     
     my $out = $self->transform( $data, $map );
     
     return $out;
}

sub transform
{
    my ( $self, $data, $map ) = ( @_ );
    
    my $object = {};
    
    # lets make the _globals accessible to object properties
    $data->{'_globals'} = delete $map->{'_globals'};
        
    foreach my $idx ( keys $map ) {
		
        my @action = split(/\:/, $idx );
		
		my $field = shift( @action );
        
		my @param = ( ref ( $map->{$idx} ) eq 'ARRAY' ) ? @{ $map->{$idx} } : ( $map->{$idx} ) ;
        
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
	
	my @results = $data =~ /$regex/g ;
	
	return \@results;
}

sub _csv
{
    my ( $self, $regex, $delimiter, $data ) = ( @_ );

    my ( $csv ) = $data =~ /$regex/;
    
    return ( $self->[CSV]->parse( trim( $csv ) ) ) ? join( $delimiter, $self->[CSV]->fields() ) : "";
}

sub _dottags {
	my ( $self, $notation, $data ) = ( @_ );
	
	return '' unless ( $notation );

    return $data if ( $notation eq '*' );

	
	foreach my $idx ( split /\./, $notation )
	{
		if ( looks_like_number( $idx ) )
		{
			# this is number so lets assume it works
			
			if ( ref( $data ) eq 'ARRAY' and scalar( $data ) >= $idx )
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
    #return "ACTIVATE";
}

1;
