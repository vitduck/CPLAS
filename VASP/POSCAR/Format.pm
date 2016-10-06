package VASP::POSCAR::Format; 

use Moose::Role; 
use MooseX::Types::Moose qw( HashRef );  
use namespace::autoclean; 
use experimental qw( signatures );   

has 'poscar_format', ( 
    is       => 'ro', 
    isa      => HashRef, 
    traits   => [ qw( Hash ) ],  
    lazy     => 1, 
    init_arg => undef, 
    builder  => '_build_format', 

    handles  => { 
        get_format => 'get' 
    }  
); 

sub write_comment ( $self ) { 
    $self->_printf( "%s\n" , $self->get_comment ) 
}

sub write_scaling ( $self ) { 
    $self->_printf( $self->get_format( 'scaling' ), $self->get_scaling ) 
} 

sub write_lattice ( $self ) { 
    for ( $self->get_lattices ) {  
        $self->_printf( $self->get_format( 'lattice' ), @$_ ) 
    }
}  

sub write_element ( $self ) { 
    if ( $self->get_version == 5 ) { 
        $self->_printf( $self->get_format( 'element' ), $self->get_elements )
    }
}

sub write_natom ( $self ) { 
    $self->_printf( $self->get_format( 'natom' ), $self->get_natoms )
}

sub write_selective ( $self ) { 
    $self->_printf( "%s\n", 'Selective Dynamics' ) if $self->get_selective;  
}

sub write_type ( $self ) { 
    $self->_printf( "%s\n", $self->get_type )
} 

sub write_coordinate ( $self ) { 
    my $format = $self->get_format( 'coordinate' ); 

    for ( sort { $a <=> $b } $self->get_indices ) {  
        $self->get_selective 
        ? $self->_printf( 
            $format, 
            $self->get_coordinate( $_ )->@*, 
            $self->get_dynamics( $_ )->@*, 
            $_ 
        )
        : $self->_printf( 
            $format, 
            $self->get_coordinate( $_ )->@*, 
            $_ 
        )   
    }
} 

sub _build_format ( $self ) { 
    return { 
        scaling    => join( '', "%19.14f", "\n" ), 
        lattice    => join( '', "%23.16f" x 3, "\n" ), 
        element    => join( '', "%5s" x $self->get_elements, "\n" ), 
        natom      => join( '', "%6d" x $self->get_natoms, "\n" ), 
        coordinate => 
            $self->get_selective
            ? join( '', "%20.16f" x 3, "%4s" x 3, "%6d", "\n" )
            : join( '', "%20.16f" x 3, "%6d", "\n" )  
    }  
} 

1 
