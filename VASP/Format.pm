package VASP::Format;  

use Moose::Role; 
use MooseX::Types::Moose 'HashRef';  

use namespace::autoclean; 
use experimental qw( signatures ); 

# VASP printing format 
has 'poscar_format', ( 
    is       => 'ro', 
    isa      => HashRef, 
    traits   => [ 'Hash' ],  
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_poscar_format', 
    handles  => { 
        get_poscar_format => 'get' 
    }  
); 

sub _build_poscar_format ( $self ) { 
    return { 
        scaling    => join( '', "%19.14f", "\n" ), 
        lattice    => join( '', "%23.16f" x 3, "\n" ), 
        element    => join( '', "%5s" x $self->get_elements, "\n" ), 
        natom      => join( '', "%6d" x $self->get_natoms,   "\n" ), 
        coordinate => ( 
            $self->selective ? 
            join( '', "%20.16f" x 3, "%4s" x 3, "%6d", "\n" ) : 
            join( '', "%20.16f" x 3, "%6d", "\n" )  
        ), 
    }  
} 

1 
