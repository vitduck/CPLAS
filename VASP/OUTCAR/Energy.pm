package VASP::OUTCAR::Energy;  

use Moose::Role;  
use MooseX::Types::Moose qw/ArrayRef RegexpRef/;  

use namespace::autoclean; 
use experimental 'signatures';  

has 'energy', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_energy', 
    handles   => { get_energy => [ get => -1 ] }
);  

has '_energy_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => "_build_energy_regex"
); 

sub _build_energy ( $self ) { 
    return [ 
        $self->slurped =~ /${ \$self->_energy_regex }/g 
    ]
} 

sub _build_energy_regex ( $self ) { 
    return qr/
        (?:
            free\ \ energy\s+TOTEN\s+=\s+
        )
        (.+?)
        (?:
            \ eV
        )
    /xs
} 

1 
