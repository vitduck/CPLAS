package VASP::OUTCAR; 

use strict;  
use warnings FATAL => 'all'; 
use namespace::autoclean; 
use feature 'signatures';  

use Moose;  
use MooseX::Types::Moose 'Str';  

no warnings 'experimental'; 

with 'IO::Reader','VASP::Force','VASP::Regex'; 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

__PACKAGE__->meta->make_immutable;

1; 
