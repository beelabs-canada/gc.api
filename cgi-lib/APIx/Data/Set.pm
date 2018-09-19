package APIx::Data::Set;

use APIx::Util::HttpClient;

use Data::Dmp qw/dd/;


sub new {
   my ( $class, $props, $http ) = ( shift,  @_ );
   
   my $self = { _debug => $props  };
   
   $self->{ 'set' } = $props;
   
   $self->{'httpclient'} = $http;
   
   return bless $self, $class;
}

sub data {
    return shift->{'set'}
}

sub httpclient
{
    return shift->{'httpclient'}
}



1;