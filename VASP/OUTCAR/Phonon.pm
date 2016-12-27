package VASP::OUTCAR::Phonon;  

use Moose::Role;  
use MooseX::Types::Moose qw/ArrayRef RegexpRef/;  

use namespace::autoclean; 
use experimental 'signatures';  

with 'Thermo::Phonon'; 

has '_eigenvalue_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { 
        qr/
            (?:
                f\ \ =.+?cm-1\s+
            )
            (.+?)
            (?:
                \ meV
            )
        /xs
    }
); 

sub _build_eigenvalue ( $self ) { 
    return [
        $self->slurped =~ /${ \$self->_eigenvalue_regex }/g
    ]
} 

1 
