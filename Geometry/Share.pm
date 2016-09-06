package Geometry::Share; 

use strictures 2; 
use List::Util qw/sum/; 

use Moose::Role; 
use MooseX::Types::Moose qw/Str Int ArrayRef HashRef/; 

use namespace::autoclean; 
use experimental qw/signatures/; 

use Periodic::Table qw/Element/;  

has 'comment', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 

    default  => sub ( $self ) { 
        return $self->read('comment') 
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
    isa       => ArrayRef[Element],
    traits    => ['Array'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('element') 
    },  

    handles   => { 
        get_elements => 'elements' 
    },  
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef[Int], 
    traits    => ['Array'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('natom') 
    },  

    handles   => { 
        set_natom  => 'set', 
        get_natom  => 'get', 
        get_natoms => 'elements', 
    },  
);  

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('lattice') 
    },  

    handles   => { 
        get_lattices => 'elements' 
    },  
);  

has 'coordinate', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => ['Hash'], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return $self->read('coordinate')
    },  

    handles   => { 
        get_coordinate       => 'get', 
        set_coordinate       => 'set', 
        delete_coordinate    => 'delete', 
    },  
); 

1; 
