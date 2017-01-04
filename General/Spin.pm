package General::Spin; 

use Moose::Role; 
use MooseX::Types::Moose qw/Num HashRef/;   

use namespace::autoclean; 
 
requires '_build_magmom';  

has 'magmom', ( 
    is        => 'ro', 
    isa       => HashRef[ Num ], 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_magmom', 
); 

1
