package VASP::Format; 

# cpan 
use Moose::Role; 
use MooseX::Types::Moose qw/Str/;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw/signatures/; 

# VASP printing format 
has "scaling_format", ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default   => sub ( $self ) { 
        return join('', "%19.14f", "\n"); 
    }, 
); 

has "lattice_format", ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default   => sub ( $self ) { 
        return join('', "%23.16f" x 3, "\n"); 
    } 
);  

has "element_format", ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default   => sub ( $self ) { 
        my $count = $self->get_elements; 
        return join('', "%5s" x $count, "\n"); 
    } 
); 

has "natom_format", ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default   => sub ( $self ) { 
        my $count = $self->get_natoms; 
        return join('', "%6d" x $count, "\n"); 
    } 
);  

has 'coordinate_format', ( 
    is       => 'ro', 
    isa      => Str, 
    lazy     => 1, 
    default  => sub ( $self ) { 
        return 
            $self->selective ? 
            join('', "%20.16f" x 3, "%4s" x 3, "%6d", "\n") : 
            join('', "%20.16f" x 3, "%6d", "\n")  
    } 
); 

1; 
