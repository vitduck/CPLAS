package VASP::POSCAR; 

use autodie; 
use strict; 
use warnings FATAL => 'all'; 

use Try::Tiny; 
use File::Copy qw( copy );  
use Moose;  
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );   
use IO::KISS; 
use Types::Periodic qw( Element );   
use VASP::POTCAR; 

use namespace::autoclean; 
use experimental qw( signatures ); 

with qw( IO::Reader IO::Writer Geometry::VASP VASP::Format );  

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
    try { $self->reader };  

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
    $self->close;  
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

sub _default_index ( $self ) { 
    return [ sort { $a <=> $b } $self->get_coordinate_indices ]
} 

sub _build_io_writer ( $self ) { 
    return (
        $self->has_save_as ? 
        IO::KISS->new( $self->save_as, 'w' ) :  
        IO::KISS->new( $self->file, 'w' ) 
    ); 
} 

sub _parse_file ( $self ) { 
    my %poscar = ();  
    
    # lattice vector 
    $poscar{comment} = $self->get_line; 
    $poscar{scaling} = $self->get_line; 
    $poscar{lattice}->@* = map [ split ' ', $self->get_line ], 0..2; 

    # natom and element 
    my ( @natoms, @elements ); 
    my @has_VASP5 = split ' ', $self->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        @elements = VASP::POTCAR->new()->get_elements;  
        @natoms   = @has_VASP5;  
        @elements = splice @elements, 0, scalar(@natoms); 
    } else { 
        $poscar{version} = 5; 
        @elements = @has_VASP5; 
        @natoms   = split ' ', $self->get_line;  
    } 
    # build list of atom
    my @atoms = map { ( $elements[$_] ) x $natoms[$_] } 0..$#elements; 
   
    # selective dynamics 
    my $has_selective = $self->get_line;  
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar{selective} = 1; 
        $poscar{type}      = $self->get_line; 
    } else { 
        $poscar{selective} = 0; 
        $poscar{type}      = $has_selective; 
    } 

    # coodinate and dynamics
    my ( @coordinates, @dynamics );  
    while ( local $_ = $self->get_line ) { 
        # blank line separate geometry and velocity blocks
        last if /^\s+$/; 
        
        my @columns = split; 
        
        # 1st 3 columns are coordinate 
        push @coordinates, [ splice @columns, 0, 3 ];  

        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        push @dynamics, ( 
            @columns == 0 || @columns == 1 ? 
            [ qw( T T T ) ] :
            [ splice @columns, 0, 3 ]
        ); 
    } 

    # indexing 
    $poscar{atom}       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $poscar{coordinate} = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  
    $poscar{dynamics}   = { map { $_+1 => $dynamics[$_]    } 0..$#dynamics    };  

    return \%poscar; 
} 

__PACKAGE__->meta->make_immutable;

1 
