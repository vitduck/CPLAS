package VASP::POSCAR; 

use Try::Tiny; 
use File::Copy qw( copy );  

use Moose;  
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );  

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
    builder   => '_build_index', 
    handles   => { 
        get_indices => 'elements' 
    }
); 

has 'dynamics', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_constraint', 
    default   => 'F F F', 
);

has 'constraint', (  
    is        => 'ro', 
    isa       => ArrayRef[ Int ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    default   => sub { $_[0]->index },  
    handles   => { 
        get_constraint_indices => 'elements'
    }
); 

has 'delete', ( 
    is        => 'ro', 
    isa       => ArrayRef[ Int ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    predicate => 'has_delete', 
    default   => sub { [] },  
    handles   => { 
        get_delete_indices => 'elements'
    }
); 

has 'backup', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_backup', 
    default   => 'POSCAR.bak', 
    trigger   => sub { copy $_[0]->file => $_[0]->backup }
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

    $self->$_ for (
        map $_->[1], 
        grep $self->${\$_->[0]}, ( 
            [ 'has_constraint', '_constraint' ], 
            [ 'has_delete'    , '_delete'     ], 
        )
    ); 
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

    $self->close_writer; 
} 

sub write_comment ( $self ) { 
    $self->printf( "%s\n" , $self->comment ) 
}

sub write_scaling ( $self ) { 
    $self->printf( $self->get_poscar_format( 'scaling' ), $self->scaling ) 
} 

sub write_lattice ( $self ) { 
    for ( $self->get_lattices ) {  
        $self->printf( $self->get_poscar_format( 'lattice' ), @$_ ) 
    }
}  

sub write_element ( $self ) { 
    $self->printf( $self->get_poscar_format( 'element' ), $self->get_elements )
}

sub write_natom ( $self ) { 
    $self->printf( $self->get_poscar_format( 'natom' ), $self->get_natoms )
}

sub write_selective ( $self ) { 
    $self->printf( "%s\n", 'Selective Dynamics' ) if $self->selective;  
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

# from IO::Writer
sub _build_writer ( $self ) { 
    my $OUTCAR = 
        $self->has_save_as 
        ? $self->save_as 
        : $self->file; 

    return IO::KISS->new( $OUTCAR, 'w' ) 
} 

# native
sub _build_index ( $self ) { 
    return [ sort { $a <=> $b } $self->get_coordinate_indices ]
} 

sub _constraint ( $self, @ ) { 
    $self->set_dynamics( 
        map { $_ =>  [ split ' ', $self->dynamics ] } $self->get_constraint_indices
    ) 
} 

# trigger
sub _delete ( $self, @ ) { 
    my @indices = $self->get_delete_indices; 

    $self->delete_atom(@indices);  
    $self->delete_coordinate(@indices); 
    $self->delete_dynamics(@indices); 

    # clear natom and element 
    $self->_clear_element; 
    $self->_clear_natom; 
}

__PACKAGE__->meta->make_immutable;

1 
