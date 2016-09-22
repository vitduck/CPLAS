package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );  
use File::Copy qw( copy );  
use Try::Tiny; 
use IO::KISS; 
use VASP::POTCAR; 
use Periodic::Table qw( Element );  
use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Writer VASP::Geometry VASP::Format ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'POSCAR' 
); 

has 'index', (   
    is        => 'ro', 
    isa       => ArrayRef [ Int ], 
    traits    => [ 'Array' ], 
    builder   => '_default_index', 
    handles   => { get_indices => 'elements' }
); 

has 'delete', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    predicate => 'has_delete', 
    default   => 0, 
    trigger   => \&_delete
); 

has 'dynamics', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_dynamics', 
    default   => 'F F F', 
    trigger   => \&_dynamics 
);


has 'backup', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_backup', 
    default   => 'POSCAR.bak', 
    trigger   => \&_backup
); 

has 'save_as', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_save_as',  
    default   => 'POSCAR.new' 
); 

sub BUILD ( $self, @ ) { 
    # cache POSCAR
    try { $self->cache };  

    # sanity check
    if ( $self->has_delete && $self->has_dynamics ) {  
        die "Thou shall not set delete and dynamics at the same time!\n"
    }
} 

sub write ( $self ) { 
    $self->write_comment; 
    $self->write_scaling; 
    $self->write_lattice; 
    $self->write_element; 
    $self->write_natom; 
    $self->write_selective; 
    $self->write_type; 
    $self->write_coordinate; 

    # close internal fh
    $self->close_writer; 
} 

sub write_comment ( $self ) {  
    $self->printf( "%s\n" , $self->comment ) 
}

sub write_scaling ( $self ) { 
    $self->printf( 
        $self->get_poscar_format( 'scaling' ), 
        $self->scaling 
    ) 
} 

sub write_lattice ( $self ) { 
    for my $lat ( $self->get_lattices ) {  
        $self->printf( 
            $self->get_poscar_format( 'lattice' ), 
            @$lat 
        ) 
    }
}  

sub write_element ( $self ) { 
    $self->printf( 
        $self->get_poscar_format( 'element' ), 
        $self->get_elements 
    )
}

sub write_natom ( $self ) { 
    $self->printf( 
        $self->get_poscar_format( 'natom' ), 
        $self->get_natoms 
    ) 
}

sub write_selective ( $self ) { 
    if ( $self->selective ) {  
        $self->printf( "%s\n", 'Selective Dynamics' )  
    }
}

sub write_type ( $self ) { 
    $self->printf( "%s\n", $self->type )
} 

sub write_coordinate ( $self ) { 
    my $format = $self->get_poscar_format( 'coordinate' ); 

    for ( sort { $a <=> $b } $self->get_coordinate_indices ) {  
        $self->selective ? 
        $self->printf( $format, $self->get_coordinate($_)->@*, $self->get_dynamics($_)->@*, $_ ) : 
        $self->printf( $format, $self->get_coordinate($_)->@*,  $_ ) ;  
    }
} 

sub _default_index ( $self ) { 
    return [ sort { $a <=> $b } $self->get_coordinate_indices ]
} 

# from IO::Writer
sub _build_writer ( $self ) { 
    return 
        $self->has_save_as ? 
        IO::KISS->new( $self->save_as, 'w' ) :  
        IO::KISS->new( $self->file, 'w' ) 
} 

# triggers 
sub _backup ( $self, @ ) { 
    copy $self->file => $self->backup 
} 

sub _dynamics ( $self, @ ) { 
    $self->set_dynamics( 
        map { $_ =>  [ split ' ', $self->dynamics ] } $self->get_indices 
    ) 
} 

sub _delete ( $self, @ ) { 
    my @indices = $self->get_indices;  

    $self->delete_atom(@indices);  
    $self->delete_coordinate(@indices); 
    $self->delete_dynamics(@indices); 

    # clear natom and element 
    $self->_clear_element; 
    $self->_clear_natom; 
}

__PACKAGE__->meta->make_immutable;

1 
