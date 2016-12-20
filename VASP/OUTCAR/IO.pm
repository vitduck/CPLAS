package VASP::OUTCAR::IO;  

use Moose::Role;  
use MooseX::Types::Moose 'Str'; 

use namespace::autoclean; 

with 'IO::Reader';  

has 'slurped', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { shift->slurp }
); 

1 
