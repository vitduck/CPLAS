package Format::POSCAR; 

use Moose::Role; 
use MooseX::Types::Moose qw( HashRef );  
use namespace::autoclean; 

use experimental qw( signatures );   

requires qw( _build_format );  

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
    $self->printf( "%s\n" , $self->comment ) 
}

sub write_scaling ( $self ) { 
    $self->printf( $self->get_format( 'scaling' ), $self->scaling ) 
} 

sub write_lattice ( $self ) { 
    for ( $self->get_lattices ) {  
        $self->printf( $self->get_format( 'lattice' ), @$_ ) 
    }
}  

sub write_element ( $self ) { 
    $self->printf( $self->get_format( 'element' ), $self->get_elements )
}

sub write_natom ( $self ) { 
    $self->printf( $self->get_format( 'natom' ), $self->get_natoms )
}

sub write_selective ( $self ) { 
    $self->printf( "%s\n", 'Selective Dynamics' ) if $self->selective;  
}

sub write_type ( $self ) { 
    $self->printf( "%s\n", $self->type )
} 

sub write_coordinate ( $self ) { 
    my $format = $self->get_format( 'coordinate' ); 

    for ( sort { $a <=> $b } $self->get_indices ) {  
        $self->selective 
        ? $self->printf( 
            $format, 
            $self->get_coordinate( $_ )->@*, 
            $self->get_dynamics( $_ )->@*, 
            $_ 
        )
        : $self->printf( 
            $format, 
            $self->get_coordinate( $_ )->@*, 
            $_ 
        )   
    }
} 

1 
