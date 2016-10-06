package VASP::POSCAR::Geometry; 

use Moose::Role; 
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( Geometry::General );  

has 'version', ( 
    is        => 'ro', 
    isa       => Int,  
    lazy      => 1, 
    reader    => 'get_version', 
    builder   => '_build_version' 
);  

has 'scaling', ( 
    is        => 'ro', 
    isa       => Str,   
    lazy      => 1, 
    reader    => 'get_scaling', 
    builder   => '_build_scaling' 
);  

has 'selective', ( 
    is        => 'ro', 
    isa       => Bool,  
    lazy      => 1, 
    reader    => 'get_selective', 
    builder   => '_build_selective'
); 

has 'type', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    reader    => 'get_type', 
    builder   => '_build_type'
); 

has 'dynamics', ( 
    is        => 'rw', 
    isa       => HashRef, 
    traits    => [ qw( Hash ) ], 
    lazy      => 1, 
    init_arg  => undef, 
    clearer   => '_clear_dynamics', 
    builder   => '_build_dynamics', 

    handles   => { 
        set_dynamics         => 'set', 
        get_dynamics         => 'get', 
        delete_dynamics      => 'delete', 
        get_dynamics_indices => 'keys', 
    },   
); 

has 'false_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   =>  '_build_false_index', 

    handles   => { 
        get_false_indices => 'elements' 
    }
); 

has 'true_index', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ qw( Array ) ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_true_index', 

    handles  => {  
        get_true_indices => 'elements' 
    } 
);  

# parse POSCAR 
sub _build_comment    ( $self ) { return $self->_get_cached( 'comment' )    }
sub _build_version    ( $self ) { return $self->_get_cached( 'version' )    } 
sub _build_scaling    ( $self ) { return $self->_get_cached( 'scaling' )    } 
sub _build_lattice    ( $self ) { return $self->_get_cached( 'lattice' )    } 
sub _build_selective  ( $self ) { return $self->_get_cached( 'selective' )  } 
sub _build_type       ( $self ) { return $self->_get_cached( 'type' )       } 
sub _build_atom       ( $self ) { return $self->_get_cached( 'atom' )       } 
sub _build_coordinate ( $self ) { return $self->_get_cached( 'coordinate' ) } 
sub _build_dynamics   ( $self ) { return $self->_get_cached( 'dynamics' )   } 

sub _build_index ( $self ) { 
    return [ sort { $a <=> $b } $self->get_coordinate_indices ] 
} 

sub _build_element ( $self ) { 
    my @elements;  

    for my $index ( $self->get_indices ) { 
        my $element = $self->get_atom( $index ); 

        next if grep $element eq $_, @elements; 
        push @elements, $element; 
    } 

    return \@elements; 
} 

sub _build_natom ( $self ) { 
    my @natoms;  

    for my $element ( $self->get_elements ) { 
        my $natom = 
            grep $element eq $_, 
            map  $self->get_atom( $_ ), 
            $self->get_indices;  

        push @natoms, $natom; 
    } 

    return \@natoms; 
} 

sub _build_false_index ( $self ) { 
    my @f_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @f_indices, $index - 1 
            if grep $_ eq 'F', $self->get_dynamics( $index )->@*;   
    }

   return \@f_indices;  
} 

sub _build_true_index ( $self ) {
    my @t_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @t_indices, $index - 1 
            if ( grep $_ eq 'T', $self->get_dynamics( $index )->@* ) == 3  
    }

    return \@t_indices;  
}

1
