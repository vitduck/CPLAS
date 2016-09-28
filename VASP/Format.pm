package VASP::Format;  

use Moose::Role; 
use MooseX::Types::Moose qw( HashRef );  

use namespace::autoclean; 
use experimental qw( signatures ); 

has 'poscar_format', ( 
    is       => 'ro', 
    isa      => HashRef, 
    traits   => [ 'Hash' ],  
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_poscar_format', 
    handles  => { 
        get_poscar_format => 'get' 
    }  
); 

1 
