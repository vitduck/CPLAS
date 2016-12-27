package Thermo::Phonon;  

use Moose::Role;  
use MooseX::Types::Moose 'ArrayRef'; 

use namespace::autoclean; 
use experimental 'signatures';  

requires '_build_eigenvalue'; 

has 'eigenvalue', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_eigenvalue',
    handles   => { get_eigenvalues => 'elements' }
); 

1 
