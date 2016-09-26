package VASP::Force; 

use Moose::Role; 

use namespace::autoclean; 

requires qw( _build_force _build_max_force ); 

has 'force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 
    builder  => '_build_force' 
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_max_force', 
    handles   => { 
        get_max_forces => 'list' 
    } 
); 

1; 
