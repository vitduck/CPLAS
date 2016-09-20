package VASP::OUTCAR; 

use strict;  
use warnings FATAL => 'all'; 

use Moose;  
use MooseX::Types::Moose qw( Str ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader VASP::Force VASP::Regex );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

__PACKAGE__->meta->make_immutable;

1; 
