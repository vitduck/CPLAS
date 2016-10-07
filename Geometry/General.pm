package Geometry::General; 

use Moose::Role; 
use MooseX::Types::Moose qw( Str ArrayRef HashRef );  
use Periodic::Table qw( Element );  
use List::Util qw( sum );  
use namespace::autoclean; 
use experimental qw( signatures );  

requires qw( 
    _build_comment 
    _build_lattice
    _build_index 
    _build_atom 
    -build_coordinate 
    _build_element 
    _build_natom 
); 

has 'comment', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    reader   => 'get_comment', 
    builder  => '_build_comment'
); 

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    builder   => '_build_lattice', 

    handles   => { 
        get_lattices => 'elements' 
    },  
);  

has 'index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    clearer   => '_clear_index', 
    builder   => '_build_index', 

    handles   => { 
        get_indices => 'elements', 
    }
); 

has 'atom', ( 
    is        => 'ro', 
    isa       => HashRef[ Element ],  
    traits    => [ qw( Hash ) ], 
    lazy      => 1, 
    clearer   => '_clear_atom', 
    builder   => '_build_atom',  

    handles   => { 
        get_atom         => 'get', 
        set_atom         => 'set',  
        delete_atom      => 'delete', 
        get_atom_indices => 'keys' 
    } 
); 

has 'coordinate', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => [ qw( Hash ) ], 
    lazy      => 1, 
    clearer   => '_clear_coordinate', 
    builder   => '_build_coordinate', 

    handles   => { 
        get_coordinate         => 'get', 
        set_coordinate         => 'set',  
        delete_coordinate      => 'delete', 
        get_coordinate_indices => 'keys' 
    }  
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    clearer   => '_clear_element', 
    builder   => '_build_element',   

    handles   => { 
        add_element   => 'push', 
        get_elements  => 'elements' 
    } 
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef,   
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    clearer   => '_clear_natom', 
    builder   => '_build_natom', 

    handles   => { 
        add_natom  => 'push', 
        get_natoms => 'elements' 
    } 
);  

1
