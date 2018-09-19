package APIx::Store;

use YAML::XS qw/LoadFile/;
use v5.16;

use APIx::Util::HttpClient;
use APIx::Data::Catalog;

use Iterator::Simple qw/iter/;

use Carp;
use Data::Dmp;

use constant {
    CONFIG  => 0,
    ITEMS => 1
};

sub new {
    my ( $class, $args, @aisles ) = ( shift, { @_ } );
    
    my $config = ( exists $args->{'config'} ) ? $args->{'config'} : {};
    
    # lets die if we cannot find a config file
    croak(" need a config file ") if ( !keys $config );
    
    # lets load up the HttpClient
    APIx::Util::HttpClient->instance( cache_dir => $config->{'httpclient'}->{'cache_dir'}, agent => $config->{'user-agent'} );
    
    my $catalog = APIx::Data::Catalog->new( $config );
    
    my $items = $catalog->items();
    
    while ( defined( my $item = $items->next ) )
    {
        say dmp $item->data();
        say dmp $item->httpclient();
    }
    
    return bless [ $config, $items ], $class;
}

sub items
{
    iter ( shift->[ITEMS] );
}


sub config
{
    shift->[CONFIG];
}
1;
