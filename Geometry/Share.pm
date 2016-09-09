package Geometry::Share; 

use Moose::Role; 
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef ); 
use Types::Periodic qw( Element );  

use List::Util qw( sum );  

use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures );  

has 'comment', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read( 'comment' ) 
    } 
); 

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 

    default  => sub ( $self ) { 
        return sum( $self->get_natoms )
    } 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => HashRef[ Element ],
    traits    => [ 'Hash' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'element' ) 
    },  

    handles   => { 
        count_element      => 'count', 
        set_element        => 'set', 
        get_element        => 'get', 
        delete_element     => 'delete', 
        get_element_indices => 'keys'
    },  
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => HashRef[ Int ], 
    traits    => [ 'Hash' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'natom' ) 
    },  

    handles   => { 
        count_natom       => 'count', 
        set_natom         => 'set', 
        get_natom         => 'get', 
        delete_natom      => 'delete',  
        get_natom_indices => 'keys'
    },  
);  

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ArrayRef ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'lattice' ) 
    },  

    handles   => { 
        get_lattices => 'elements' 
    },  
);  

has 'coordinate', ( 
    is        => 'ro', 
    isa       => HashRef[ ArrayRef ],  
    traits    => [ 'Hash' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'coordinate' )
    },  

    handles   => { 
        has_coordinate         => 'exists', 
        get_coordinate         => 'get', 
        set_coordinate         => 'set', 
        delete_coordinate      => 'delete', 
        get_coordinate_indices => 'keys',  
    },  
); 

sub get_elements ( $self ) { 
    return $self->get_element( sort { $a <=> $b } $self->get_element_indices ) 
} 

sub get_natoms ( $self ) { 
    return $self->get_natom( sort { $a <=> $b } $self->get_natom_indices ) 
}

1; 
