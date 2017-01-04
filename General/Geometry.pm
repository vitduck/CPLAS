package General::Geometry; 

use Moose::Role; 
use MooseX::Types::Moose qw/Str Int ArrayRef/;  
use Periodic::Table 'Element';  
use List::Util 'sum';  

use namespace::autoclean; 
use experimental 'signatures';  

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
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder  => '_build_lattice', 
    handles   => { get_lattices => 'elements' }
);  

has 'atom', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    clearer   => 'clear_atom', 
    builder  => '_build_atom', 
    handles   => { 
        add_atom  => 'push',
        get_atoms => 'elements' 
    } 
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef,   
    traits    => [ 'Array' ], 
    lazy      => 1, 
    clearer   => 'clear_natom', 
    builder   => '_build_natom', 
    handles   => { 
        add_natom  => 'push', 
        get_natoms => 'elements' 
    } 
);  

has 'coordinate', ( 
    is        => 'ro', 
    isa       => ArrayRef,  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    clearer   => 'clear_coordinate', 
    builder   => '_build_coordinate', 
    handles   => {  
        add_coordinate  => 'push', 
        get_coordinates => 'elements'
    }
); 

1
