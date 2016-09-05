package VASP::OUTCAR; 

use Moose;  

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures/;

with qw/IO::RW VASP::Force/;  

# Moose attributes 
has '+file', ( 
    default   => 'OUTCAR' 
); 

__PACKAGE__->meta->make_immutable;

1; 
