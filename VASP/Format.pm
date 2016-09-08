package VASP::Format;  

use Moose::Role; 
use MooseX::Types::Moose qw( HashRef );  

use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures );  

# VASP printing format 
has 'poscar_format', ( 
    is       => 'ro', 
    isa      => HashRef, 
    traits   => [ 'Hash' ],  
    lazy     => 1, 
    init_arg => undef, 

    default  => sub ( $self ) { 
        return { 
            scaling    => join('', "%19.14f", "\n"), 
            lattice    => join('', "%23.16f" x 3, "\n"), 
            element    => join('', "%5s" x $self->count_element, "\n"), 
            natom      => join('', "%6d" x $self->count_natom, "\n"), 
            coordinate => ( 
                $self->selective ? 
                join('', "%20.16f" x 3, "%4s" x 3, "%6d", "\n") : 
                join('', "%20.16f" x 3, "%6d", "\n")  
            ), 
        }  
    }, 

    handles  => { 
        get_poscar_format => 'get' 
    },  
); 

1; 
