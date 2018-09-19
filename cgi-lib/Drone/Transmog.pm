package Drone::Transmorg;


use JSON::MaybeXS;
use Scalar::Util qw/looks_like_number/;
use Digest::SHA qw(sha256_hex);
use Text::Trim;
use String::Truncate;
use Drone::Template;
use Text::CSV;

use constant {
    TEMPLATE => 0,
    CSV => 1
    }; 

my $datamap = {};
 
sub new {
    my ( $class, $args ) = ( shift, { @_ } );
    # lets delete keys we ignore
    delete $args->{ $_ } for ( [ 'redirect', 'duplicates' ] );
    
    return bless ([
          Drone::Template->new(),
          Text::CSV->new()
      ], $class );
   
}

sub set
{
    my ( $self, $action, $data ) = ( @_ );
    
    my $set = { %$action, %{ $data } };
    
    delete $set->{ $_ } for ( [ 'redirect', 'duplicates' ] );
    
    $datamap = $set;
    
}

sub _truncate
{
    my ( $self, $data ) = ( @_ );
    
    return String::Truncate::elide( $data, 225 );
}

sub _template
{
     my ( $self, $template, $data ) = ( @_ );

     return $self->[TEMPLATE]->render( $template, $data );
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
            # return the notation since it must be a static value
			return $notation;
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
