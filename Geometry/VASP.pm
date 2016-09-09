package Geometry::VASP; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef ); 
use Types::Periodic qw( Element );  

use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures ); 

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 

    default   => sub ( $self ) {  
        return $self->read( 'version' )
    }
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'scaling' ) 
    } 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'selective' ) 
    } 
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'type' ) 
    } 
); 

has 'dynamics_tag', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        $self->read( 'dynamics_tag' )
    },  

    handles   => { 
        get_dynamics_tag         => 'get', 
        set_dynamics_tag         => 'set', 
        delete_dynamics_tag      => 'delete', 
        get_dynamics_tag_indices => 'keys'
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    lazy      => 1, 
    init_arg  => undef,

    default   => sub ( $self ) { 
        my $false = [ ]; 

        for my $index ( $self->get_dynamics_tag_indices ) { 
            if ( grep $_ eq 'F', $self->get_dynamics_tag($index)->@* ) { 
                push $false->@*, $index;  
            }
        }

        return $false  
    },  
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    lazy      => 1, 
    init_arg  => undef,

    default   => sub ( $self ) { 
        my $true = [ ]; 

        for my $index ( $self->get_dynamics_tag_indices ) { 
            if ( ( grep $_ eq 'T', $self->get_dynamics_tag($index)->@* ) == 3 ) { 
                push $true->@*, $index; 
            }
        }

        return $true 
    } 
);  

1; 
