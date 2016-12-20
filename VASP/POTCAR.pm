package VASP::POTCAR; 

use Moose;  
use MooseX::Types::Moose qw/Str ArrayRef/;  
use VASP::Types 'Pseudo'; 

use namespace::autoclean; 
use experimental 'signatures';  

extends 'VASP::POTCAR::Getopt'; 

with 'VASP::POTCAR::IO';  
with 'VASP::POTCAR::Pseudo';  

has '+input', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+output', ( 
    init_arg  => undef, 
    default   => 'POTCAR'
); 

has '+o_mode', ( 
    default   => 'a'
); 

has 'xc', ( 
    is        => 'ro', 
    isa       => Pseudo, 
    lazy      => 1, 
    reader    => 'get_xc', 
    default   => 'PAW_PBE', 

    documentation => 'XC potential'
); 

__PACKAGE__->meta->make_immutable;

1
