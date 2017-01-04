package General::Energy; 

use Moose::Role; 
use MooseX::Types::Moose qw/ArrayRef/;  

use namespace::autoclean; 
 
requires '_build_energy';  

has 'energy', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_energy', 
    handles   => { 
        get_energies     => 'elements', 
        get_final_energy => [ get => -1 ] 
    }
);  

1
