package VASP::OUTCAR::Energy;  

use Moose::Role;  
use MooseX::Types::Moose qw/ArrayRef RegexpRef/;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'VASP::Energy'; 

has '_energy_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { 
        qr/
            (?:
                free\ \ energy\s+TOTEN\s+=\s+
            )
            (.+?)
            (?:
                \ eV
            )
        /xs
    } 
); 

sub _build_energy ( $self ) { 
    return [ 
        $self->slurped =~ /${ \$self->_energy_regex }/g 
    ]
} 

1 
