package Geometry::General; 

use Moose::Role; 
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef );  
use Periodic::Table qw( Element ); 

use List::Util qw( sum );  

use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( 
    _build_comment 
    _build_lattice 
    _build_atom 
    _build_coordinate 
    _build_element
    _build_natom
); 

has 'comment', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    builder  => '_build_comment'
); 

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_lattice', 
    handles   => { 
        get_lattices => 'elements' 
    },  
);  

has 'indexed_atom', ( 
    is        => 'ro', 
    isa       => HashRef[ Element ],  
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    builder   => '_build_atom',  
    handles   => { 
        get_atom         => 'get', 
        get_atom_indices => 'keys',  
        delete_atom      => 'delete'
    } 
); 

has 'indexed_coordinate', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    builder   => '_build_coordinate', 
    handles   => { 
        get_coordinate         => 'get', 
        get_coordinate_indices => 'keys',  
        delete_coordinate      => 'delete', 
    }  
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_element',   
    clearer   => '_clear_element', 
    handles   => { 
        get_elements  => 'elements' 
    } 
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef,   
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_natom', 
    clearer   => '_clear_natom', 
    handles   => { 
        get_natoms => 'elements' 
    } 
);  

1
