package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose 'Str';  
use Try::Tiny; 
use File::Copy 'copy';  
use IO::KISS; 
use VASP::POTCAR; 
use Periodic::Table qw( Element ); 

use namespace::autoclean; 
use experimental 'signatures';  

with qw( IO::Reader IO::Writer IO::Cache );  
with qw( Geometry::POSCAR Format::POSCAR );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'POSCAR' 
); 

has 'backup_file', ( 
    is        => 'ro', 
    isa       => Str, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { shift->file.'.old' } 
); 

has 'save_as', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    init_arg  => undef,
    default   => sub { shift->file } 
); 

sub BUILD ( $self, @ ) { 
    # cache POSCAR
    try { $self->cache };  
} 

sub initialize ( $self ) {
    $self->_clear_reader; 
    $self->_clear_writer; 
    $self->_clear_cache; 
} 

sub update ( $self ) { 
    $self->_clear_index; 
    $self->_clear_element; 
    $self->_clear_natom; 
} 

sub backup ( $self, $poscar = $self->backup_file ) { 
    copy $self->file => $poscar
} 

sub delete ( $self, @indices ) { 
    $self->delete_atom( @indices );  
    $self->delete_dynamics( @indices ); 
    $self->delete_coordinate( @indices ); 

    $self->update; 
}

sub freeze ( $self, $dynamics, @indices ) { 
    @indices = @indices ? @indices : $self->get_indices;  
    
    $self->set_dynamics( 
        map { $_ => [ split ' ', $dynamics ] } @indices  
    )  
} 

sub unfreeze ( $self, @indices ) { 
    $self->freeze( 'T T T', @indices ) 
} 

sub write ( $self, $poscar = $self->save_as ) { 
    $self->save_as( $poscar ); 

    $self->write_comment; 
    $self->write_scaling; 
    $self->write_lattice; 
    $self->write_element; 
    $self->write_natom; 
    $self->write_selective; 
    $self->write_type; 
    $self->write_coordinate; 

    $self->_close_writer; 
}

########### 
# BUILDER #
########### 

# IO::Reader
sub _build_reader ( $self ) { return IO::KISS->new( $self->file, 'r' ) }

# IO::Writer 
sub _build_writer ( $self ) { return IO::KISS->new( $self->save_as, 'w' ) } 

# IO::Cache 
sub _build_cache ( $self ) { 
    my %poscar = ();  

    # remove \n
    $self->_chomp_reader; 

    # header 
    $poscar{ comment } = $self->_get_line; 
    
    # lattice vectors 
    $poscar{ scaling } = $self->_get_line; 
    $poscar{ lattice }->@* = map [ split ' ', $self->_get_line  ], 0..2; 

    # natom and element 
    my ( @natoms, @elements ); 
    my @has_VASP5 = split ' ', $self->_get_line; 
    if ( ! grep Element->check( $_ ), @has_VASP5 ) { 
        $poscar{ version } = 4; 
        # get elements from POTCAR and synchronize with @natoms
        @elements = VASP::POTCAR->new()->get_elements;  
        @natoms   = @has_VASP5;  
        @elements = splice @elements, 0, scalar( @natoms ); 
    } else { 
        $poscar{ version } = 5; 
        @elements = @has_VASP5; 
        @natoms   = split ' ', $self->_get_line; 
    } 

    # build list of atom
    my @atoms = map { ( $elements[$_] ) x $natoms[$_] } 0..$#elements; 
   
    # selective dynamics 
    my $has_selective = $self->_get_line; 
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar{ selective } = 1; 
        $poscar{ type }      = $self->_get_line; 
    } else { 
        $poscar{ selective } = 0; 
        $poscar{ type }      = $has_selective; 
    } 

    # coodinate and dynamics
    my ( @coordinates, @dynamics );  
    while ( defined( local $_ = $self->_get_line ) ) { 
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
    $poscar{ atom }       = { map { $_+1 => $atoms[ $_ ] } 0..$#atoms };   
    $poscar{ dynamics }   = { map { $_+1 => $dynamics[ $_ ] } 0..$#dynamics };  
    $poscar{ coordinate } = { map { $_+1 => $coordinates[ $_ ] } 0..$#coordinates };  
    
    $self->_close_reader; 

    return \%poscar; 
}

# Geometry::POSCAR
sub _build_version    ( $self ) { return $self->cache->{ 'version' } } 
sub _build_comment    ( $self ) { return $self->cache->{ 'comment' } }
sub _build_scaling    ( $self ) { return $self->cache->{ 'scaling' } } 
sub _build_lattice    ( $self ) { return $self->cache->{ 'lattice' } } 
sub _build_selective  ( $self ) { return $self->cache->{ 'selective' } } 
sub _build_type       ( $self ) { return $self->cache->{ 'type' } } 
sub _build_atom       ( $self ) { return $self->cache->{ 'atom' } } 
sub _build_coordinate ( $self ) { return $self->cache->{ 'coordinate' } } 
sub _build_dynamics   ( $self ) { return $self->cache->{ 'dynamics' } } 

# by default, index is built from coordinate_indices
sub _build_index ( $self ) { 
    return [ sort { $a <=> $b } $self->get_coordinate_indices ] 
} 

# similar to List::More qw( unique )
sub _build_element ( $self ) { 
    my @elements;  

    for my $index ( $self->get_indices ) { 
        my $element = $self->get_atom( $index ); 

        next if grep $element eq $_, @elements; 
        push @elements, $element; 
    } 

    return \@elements; 
} 

# simple count via grep in scalar context  
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

# for VASP::Force 
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

# Format::POSCAR
sub _build_format ( $self ) { 
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

__PACKAGE__->meta->make_immutable;

1 
