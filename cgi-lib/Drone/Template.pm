package Drone::Template;

use Mustache::Simple;

use constant {
    ENGINE  => 0,
    HELPERS => 1
};

sub new {
    my ( $class, $args ) = ( shift, {@_} );

    my $stache = Mustache::Simple->new();

    my $helpers = {
        '@uppercase' => sub { return uc(shift) },
        '@lowercase' => sub { return lc(shift) }
    };

    return bless [ $stache, $helpers ], $class;
}

sub render {
    my ( $self, $template, $data ) = @_;

    $data = { %{ $self->[HELPERS] }, %{ $data } };

    return $self->[ENGINE]->render( $template, $data );
}

1;
