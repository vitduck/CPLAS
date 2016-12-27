package Thermo::ZPE; 

use Moose::Role;  
use MooseX::Types::Moose 'Num'; 
use List::Util 'sum'; 

use namespace::autoclean; 
use experimental 'signatures';  

requires 'get_eigenvalues'; 

has 'zpe', ( 
    is        => 'ro', 
    isa       => Num, 
    init_arg  => undef, 
    lazy      => 1, 
    reader    => 'get_zpe', 
    default   => sub { 0.5*sum( shift->get_eigenvalues )/1000.0 } 
); 

1 
