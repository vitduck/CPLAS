package VASP::Spin; 

use Moose::Role; 
use MooseX::Types::Moose qw( Num HashRef );  
use namespace::autoclean; 
 
requires qw( _build_magmom ); 

has 'magmom', ( 
    is        => 'ro', 
    isa       => HashRef[ Num ], 
    traits    => [ qw( Hash ) ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_magmom', 
); 

 1
