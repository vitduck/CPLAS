package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );  
use IO::KISS; 
use VASP::POTCAR; 
use Periodic::Table qw( Element );  

use Try::Tiny; 
use File::Copy qw( copy );  

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( IO::Reader IO::Writer IO::Cache ); 
with qw( Geometry::General ); 
with qw( VASP::Geometry );  
with qw( VASP::Format ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'POSCAR' 
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
    default   => sub ( $self ) { $self->index },  
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
    trigger   => sub { }
); 

has 'save_as', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_save_as',  
    default   => 'POSCAR.new' 
); 

has 'index', (   
    is        => 'ro', 
    isa       => ArrayRef [ Int ], 
    traits    => [ 'Array' ], 
    default   => sub ( $self ) { [ sort { $a <=> $b } $self->get_coordinate_indices ] }, 
    handles   => { 
        get_indices => 'elements' 
    }
); 

sub BUILD ( $self, @ ) { 
    # cache POSCAR
    try { $self->cache };  

    $self->$_ for (
        map $_->[1], 
        grep $self->${\$_->[0]}, ( 
            [ 'has_backup'    , '_backup'     ], 
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

# IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

# IO::Writer
sub _build_writer ( $self ) { 
    my $OUTCAR = 
        $self->has_save_as 
        ? $self->save_as 
        : $self->file; 

    return IO::KISS->new( $OUTCAR, 'w' ) 
} 

# IO::Cache 
sub _build_cache ( $self ) { 
    my %poscar = ();  

    # remove \n
    $self->chomp_reader; 

    # header 
    $poscar{comment} = $self->get_line; 
    
    # lattice vectors 
    $poscar{scaling} = $self->get_line; 
    $poscar{lattice}->@* = map [ split ' ', $self->get_line  ], 0..2; 

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
    while ( defined( local $_ = $self->get_line ) ) { 
        # blank line separate geometry and velocity blocks
        last if /^\s+$/; 
        
        # 1st 3 columns are coordinate 
        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        my @columns = split; 
        push @coordinates, [ splice @columns, 0, 3 ];  
        push @dynamics, ( 
            @columns == 0 || @columns == 1
            ? [ qw( T T T ) ] 
            : [ splice @columns, 0, 3 ]
        ); 
    } 
    
    # indexing 
    $poscar{atom}       = { map { $_+1 => $atoms[$_]       } 0..$#atoms       };   
    $poscar{coordinate} = { map { $_+1 => $coordinates[$_] } 0..$#coordinates };  
    $poscar{dynamics}   = { map { $_+1 => $dynamics[$_]    } 0..$#dynamics    };  
    
    $self->close_reader; 

    return \%poscar; 
} 

# Geometry::General 
sub _build_comment ( $self ) { 
    return $self->cache->{'comment'} 
} 

sub _build_lattice ( $self ) { 
    return $self->cache->{'lattice'} 
} 

sub _build_atom  ( $self ) { 
    return $self->cache->{'atom'} 
}    

sub _build_coordinate ( $self ) { 
    return $self->cache->{'coordinate'} 
} 

sub _build_element ( $self ) { 
    my @elements;  

    for my $index ( sort { $a <=> $b } $self->get_atom_indices ) { 
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
            $self->get_atom_indices; 

        push @natoms, $natom; 
    } 

    return \@natoms; 
} 

# VASP::Geometry 
sub _build_version ( $self ) { 
    return $self->cache->{'version'} 
} 

sub _build_scaling ( $self ) { 
    return $self->cache->{'scaling'} 
}

sub _build_selective ( $self ) { 
    return $self->cache->{'selective'} 
} 

sub _build_type ( $self ) { 
    return $self->cache->{'type'} 
} 

sub _build_dynamics ( $self ) { 
    return $self->cache->{'dynamics'} 
} 

sub _build_false_index ( $self ) { 
    my @f_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @f_indices, $index - 1 
            if grep $_ eq 'F', $self->get_dynamics($index)->@*;   
    }

   return \@f_indices;  
} 

sub _build_true_index ( $self ) {
    my @t_indices = ();  

    for my $index ( $self->get_dynamics_indices ) { 
        # off-set index by 1
        push @t_indices, $index - 1 
            if ( grep $_ eq 'T', $self->get_dynamics($index)->@* ) == 3  
    }

    return \@t_indices;  
}

# VASP::Format 
sub _build_poscar_format ( $self ) { 
    return { 
        scaling    => join( '', "%19.14f", "\n" ), 
        lattice    => join( '', "%23.16f" x 3, "\n" ), 
        element    => join( '', "%5s" x $self->get_elements, "\n" ), 
        natom      => join( '', "%6d" x $self->get_natoms, "\n" ), 
        coordinate => 
            $self->selective
            ? join( '', "%20.16f" x 3, "%4s" x 3, "%6d", "\n" )
            : join( '', "%20.16f" x 3, "%6d", "\n" )  
    }  
} 

sub _backup ( $self ) { 
    copy $self->file => $self->backup 
} 

sub _constraint ( $self ) { 
    $self->set_dynamics( 
        map { $_ =>  [ split ' ', $self->dynamics ] } $self->get_constraint_indices
    ) 
} 

sub _delete ( $self ) { 
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
