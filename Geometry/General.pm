package Geometry::General; 

use Moose::Role; 
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef );  
use List::Util 'sum';   
use Periodic::Table qw( Element );  
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

has 'lattice', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
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
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    builder   => '_build_coordinate', 
    handles   => { 
        get_coordinate         => 'get', 
        get_coordinate_indices => 'keys',  
        delete_coordinate      => 'delete', 
    }  
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

sub _build_comment     ( $self ) { return $self->read( 'comment' )     }
sub _build_total_natom ( $self ) { return $self->read( 'total_natom' ) }
sub _build_lattice     ( $self ) { return $self->read( 'lattice' )     }
sub _build_atom        ( $self ) { return $self->read( 'atom' )        }
sub _build_coordinate  ( $self ) { return $self->read( 'coordinate' )  }

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
