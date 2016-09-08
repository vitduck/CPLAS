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
    isa       => ArrayRef[ Element ],
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'element' ) 
    },  

    handles   => { 
        set_element    => 'set', 
        get_element    => 'get', 
        delete_element => 'delete', 
        get_elements   => 'elements'
    },  
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Int ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'natom' ) 
    },  

    handles   => { 
        set_natom    => 'set', 
        get_natom    => 'get', 
        delete_natom => 'delete', 
        get_natoms   => 'elements' 
    },  
);  

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'lattice' ) 
    },  

    handles   => { 
        get_lattices => 'elements' 
    },  
);  

has 'index', ( 
    is        => 'rw', 
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'index' ); 
    },  

    handles   => { 
        has_index    => 'exists', 
        get_index    => 'get', 
        get_indices  => 'keys',  
        delete_index => 'delete', 
    },  
); 

has 'coordinate', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read( 'coordinate' )
    },  

    handles   => { 
        get_coordinate         => 'get', 
        set_coordinate         => 'set', 
        delete_coordinate      => 'delete', 
        get_coordinate_indices => 'keys',  
    },  
); 

1; 
