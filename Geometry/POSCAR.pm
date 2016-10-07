package Geometry::POSCAR;  

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( Geometry::General );  

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    reader    => 'get_version', 
    builder   => '_build_version' 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    reader    => 'get_scaling', 
    builder   => '_build_scaling' 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    reader    => 'get_selective', 
    builder   => '_build_selective'
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_type', 
    builder   => '_build_type'
); 

has 'dynamics', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ qw( Hash ) ], 
    lazy      => 1, 
    init_arg  => undef, 
    clearer   => '_clear_dynamics', 
    builder   => '_build_dynamics', 

    handles   => { 
        set_dynamics         => 'set', 
        get_dynamics         => 'get', 
        delete_dynamics      => 'delete', 
        get_dynamics_indices => 'keys', 
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   =>  '_build_false_index', 

    handles   => { 
        get_false_indices => 'elements' 
    }
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 

    handles  => {  
        get_true_indices => 'elements' 
    } 
);  

1
