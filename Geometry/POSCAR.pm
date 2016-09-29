package Geometry::POSCAR; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );

use namespace::autoclean; 
use experimental 'signatures';  

with 'Geometry::General';  

requires qw( 
    _build_version 
    _build_scaling 
    _build_selective 
    _build_type 
    _build_dynamics 
    _build_false_index
    _build_true_index 
); 

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    builder   => '_build_version' 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    builder   => '_build_scaling' 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    builder   => '_build_selective'
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
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
