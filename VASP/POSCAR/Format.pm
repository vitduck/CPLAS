package Format::POSCAR;  

use Moose::Role; 
use MooseX::Types::Moose 'Str'; 

use namespace::autoclean; 
use experimental 'signatures'; 

has 'scaling_format', ( 
    is        => 'ro', 
    isa       => Str,
    lazy      => 1, 
    init_arg  => undef,
    default   => "%19.14f\n"
); 

has 'lattice_format', ( 
    is        => 'ro', 
    isa       => Str,
    lazy      => 1, 
    init_arg  => undef,
    default   => sub { join( '', "%23.16f" x 3, "\n" ) }  
); 

has 'atom_format', ( 
    is        => 'ro', 
    isa       => Str,
    lazy      => 1, 
    init_arg  => undef,
    default   => sub { join( '', "%5s" x shift->get_elements, "\n" ) }
); 

has 'natom_format', ( 
    is        => 'ro', 
    isa       => Str,
    lazy      => 1, 
    init_arg  => undef,
    default   => sub { join( '', "%5s" x shift->get_natoms, "\n" ) }
); 

has 'coordinate', ( 
    is        => 'ro', 
    isa       => Str,
    lazy      => 1, 
    init_arg  => undef,
    default   => sub { 
        shift->get_selective
        ? join( '', "%20.16f" x 3, "%4s" x 3, "%6d", "\n" )
        : join( '', "%20.16f" x 3, "%6d", "\n"            )
    }
); 

1
