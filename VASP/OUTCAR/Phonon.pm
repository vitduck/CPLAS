package VASP::OUTCAR::Phonon;  

use Moose::Role;  
use MooseX::Types::Moose qw/ArrayRef RegexpRef/;  

use namespace::autoclean; 
use experimental 'signatures';  

has 'eigenvalue', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_eigenvalue',
    handles   => { get_eigenvalues => 'elements' }
); 

has '_eigenvalue_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => "_build_eigenvalue_regex"
); 

sub _build_eigenvalue ( $self ) { 
    return [
        $self->slurped =~ /${ \$self->_eigenvalue_regex }/g
    ]
} 

sub _build_eigenvalue_regex ( $self ) { 
    return qr/
        (?:
            f\ \ =.+?cm-1\s+
        )
        (.+?)
        (?:
            \ meV
        )
    /xs
}

1 
