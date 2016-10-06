package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  
use IO::KISS; 
use VASP::POSCAR;  
use Try::Tiny; 
use PDL::Lite; 
use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader );  

has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
) 

__PACKAGE__->meta->make_immutable;

1 
