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
with qw( VASP::OUTCAR::Reader ); 
with qw( VASP::OUTCAR::Regex );  
with qw( VASP::OUTCAR::Force );  

has '+input', ( 
    init_arg  => undef,
    default   => 'OUTCAR' 
) 

has 'poscar_indices', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { VASP::POSCAR->new },  

    handles   => [ 
        qw(  
            get_true_indices 
            get_false_indices
        )
    ]
); 

__PACKAGE__->meta->make_immutable;

1 
