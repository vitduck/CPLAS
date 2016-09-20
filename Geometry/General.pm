package Geometry::General; 

use strict; 
use warnings FATAL => 'all'; 

use List::Util qw( sum );  
use Moose::Role; 
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef ); 
use Types::Periodic qw( Element );  

use namespace::autoclean; 
use experimental qw( signatures );  

has 'comment', ( 
    is       => 'ro', 
    isa      => Str,  
    lazy     => 1, 
    builder  => '_build_comment', 
); 

has 'total_natom', ( 
    is       => 'ro', 
    isa      => Int, 
    lazy     => 1, 
    builder  => '_build_total_natom', 
); 

has 'element', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Element ],
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_element',   
    clearer   => '_clear_element', 
    handles   => { get_elements  => 'elements' } 
); 

has 'natom', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Int ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_natom', 
    clearer   => '_clear_natom', 
    handles   => { get_natoms => 'elements' } 
);  

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ArrayRef ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    builder   => '_build_lattice', 
    handles   => { get_lattices => 'elements' },  
);  

has 'indexed_atom', ( 
    is        => 'ro', 
    isa       => HashRef[ Element ],  
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    builder   => '_build_atom',  
    handles   => { 
        get_atom         => 'get', 
        get_atom_indices => 'keys',  
        delete_atom      => 'delete'
    } 
); 

has 'indexed_coordinate', ( 
    is        => 'ro', 
    isa       => HashRef[ ArrayRef ],  
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    builder   => '_build_coordinate', 
    handles   => { 
        get_coordinate         => 'get', 
        get_coordinate_indices => 'keys',  
        delete_coordinate      => 'delete', 
    }  
); 

sub _build_total_natom ( $self ) { 
    return sum( $self->get_natoms ) 
}   

sub _build_element ( $self ) { 
    my @elements = (); 

    for my $index ( sort { $a <=> $b } $self->get_atom_indices ) { 
        my $element = $self->get_atom( $index ); 

        next if grep $element  eq $_, @elements; 
        push @elements, $element; 
    } 

    return \@elements; 
} 

sub _build_natom ( $self ) { 
    my @natoms = ();  

    for my $element ( $self->get_elements ) { 
        my $natom = (
            grep $element eq $_, 
            map  $self->get_atom( $_ ), 
            $self->get_atom_indices 
        ); 
        push @natoms, $natom; 
    } 

    return \@natoms; 
} 

1
