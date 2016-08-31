package VASP::Geometry; 

# cpan 
use Moose::Role; 
use MooseX::Types::Moose qw/ArrayRef Str Int/; 
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# Moose type 
use VASP::Periodic qw/Element/; 

# Moose attribute 
has 'comment', ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default   => 'Geometry', 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[Element],
    traits    => ['Array'], 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [] 
    },   
    handles   => { 
        get_element  => 'shift', 
        get_elements => 'elements', 
    }, 
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef[Int], 
    traits    => ['Array'], 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [] 
    },   
    handles   => { 
        get_natom  => 'shift', 
        get_natoms => 'elements', 
    }, 
);  

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [ ] 
    },  
    handles   => { 
        get_lattice  => 'shift', 
        get_lattices => 'elements', 
    },  
);  

has 'coordinate', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => ['Array'], 
    lazy      => 1, 
    default   => sub ( $self ) { 
        return [] 
    }, 
    handles   => { 
        get_coordinate  => 'shift', 
        get_coordinates => 'elements', 
    }, 
); 

1; 
