package APIx::Data::Catalog;

use APIx::Data::Set;

use APIx::Util::HttpClient;
use APIx::Util::Template;

use Data::Dmp;

use constant {
    SETS => 0
};

sub new {
    my ( $class, $config, @inventory ) = ( shift, shift );
        
    my $resources  = delete $config->{'catalog'};
    
    push @inventory, $class->inventory( $_ , $config->{'httpclient'} ) for ( @$resources );
     
    return bless [ 
        \@inventory
        ], $class;
}

# inventory
# @param - $resource data
# @param - $http overides
##################################
sub inventory
{
    my ($self, $resource, $httpclient ) = @_;
    
    
    # step 1. lets bake the whole object
    my ( $set, $resources, $httpoveride ) = (
        delete $resource->{'set'},
        delete $resource->{'resources'}
    );
    
    if ( exists $resource->{'httpclient'} )
    {
        my $overide = delete $resource->{'httpclient'};
        $httpclient = { %$httpclient, %$overide };
    }
    
    # every resource has an array of uri's
    foreach my $uri ( @$resources ) {
        # lets hit the URI to see if it is end content or more
        my $data = { %$uri, %$resource };
        
        push @dataset, APIx::Data::Set->new( $data, $httpclient )
    }
    
     
    # We need to rebrand the uri with this as well
    #if ( $merge )
    #{                
        # We need to make the callout
    #    $self->[HTTP]
    #    $data->{'uri'} = $self->[TEMPLATE]->render( $data->{'merge'}, )
    #}
  
    return @dataset;
}


sub items
{
    return shift->[SETS];
}

1;
