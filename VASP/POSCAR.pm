package VASP::POSCAR; 

use Moose;  
use MooseX::Types::Moose qw( Bool Str Int ArrayRef HashRef );   
use Types::Periodic qw( Element );   
use File::Copy qw( copy );  
use Try::Tiny; 

use autodie; 
use strictures 2; 
use namespace::autoclean; 
use experimental qw( signatures ); 

use IO::KISS; 
use VASP::POTCAR; 
with qw( IO::Parser Format::VASP ), 
     qw( Geometry::Share Geometry::VASP );  

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'POSCAR' 
); 

has 'delete', ( 
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    predicate => 'has_delete', 

    handles   => {  
        get_delete_indices => 'elements' 
    } 
); 

has 'constraint', (   
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    predicate => 'has_constraint', 
    
    handles   => {  
        get_constraints => 'elements' 
    } 
); 

has 'backup', ( 
    is        => 'ro', 
    isa       => Str, 
    predicate => 'has_backup', 
); 

has 'save_as', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_save_as',  
    default => 'POSCAR.new', 
); 

has '_indexed_coordinate', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ArrayRef ], 
    traits    => [ 'Array' ], 
    lazy      => 1, 
    
    default   => sub ( $self ) { 
        my @indices = sort { $a <=> $b } $self->get_coordinate_indices; 
        return [
            $self->selective ? 
            map [ 
                $self->get_coordinate($_)->@*, 
                $self->get_dynamics_tag($_)->@*, 
                $_+1 
            ], @indices : 
            map [ 
                $self->coordinate->[$_]->@*, 
                $_+1 
            ], @indices 
        ]
    },  

    handles => { 
        get_indexed_coordinates => 'elements'
    }
); 

sub BUILD ( $self, @args ) { 
    # cache POSCAR
    try { $self->parser };  

    # processing tags 
    $self->_backup     if $self->has_backup;  
    $self->_delete     if $self->has_delete;; 
    $self->_constraint if $self->has_constraint; 
} 

sub write ( $self ) { 
    # if save_as is not set, overwrite the original POSCAR 
    my $fh = 
        $self->has_save_as ? 
        IO::KISS->new( $self->save_as, 'w' ) :  
        IO::KISS->new( $self->file, 'w' ); 
   
    $fh->printf( "%s\n" , $self->comment ); 
    $fh->printf( $self->get_format( 'scaling' ), $self->scaling ); 
    $fh->printf( $self->get_format( 'lattice' ), @$_ ) for $self->get_lattices; 
    $fh->printf( $self->get_format( 'element' ), $self->get_elements ); 
    $fh->printf( $self->get_format( 'natom'   ), $self->get_natoms    ); 
    $fh->printf( "%s\n", 'Selective Dynamics' ) if $self->selective; 
    $fh->printf( "%s\n", $self->type ); 
    $fh->printf( $self->get_format( 'coordinate' ), @$_ ) for $self->get_indexed_coordinates; 

    $fh->close; 
} 

sub _backup ( $self ) { 
    copy $self->file => $self->backup
} 

sub _delete ( $self ) { 
    my @indices = 
        grep $self->has_coordinate($_), 
        map $_ - 1, 
        $self->get_delete_indices;  

    # delte corresponding constraint and coordinate 
    $self->delete_coordinate  ( @indices ); 
    $self->delete_dynamics_tag( @indices ); 
    
    # private synchornization 
    $self->_update_natom_and_element; 
} 

sub _update_natom_and_element ( $self, @indices ) { 
    # debug 
    use Data::Printer; 
    
    # construct the boundaries 
    # Ex: @natom = ( 10, 20, 40 ) -> @boundaries = ( 10, 30, 70 )
    my $bound      = 0; 
    my @boundaries = (); 
    push @boundaries, ( $bound += $_ ) for $self->get_natoms; 
    
    # cache natom 
    my @natoms = $self->get_natoms; 
    for my $delete ( $self->get_delete_indices ) { 
        # takes the lower bound only 
        my ( $index )    = grep { $delete <= $boundaries[$_] } 0..$#boundaries;  
        $natoms[$index] -= 1; 
    } 

    # now update the original natom and element 
    $self->set_natom( map { $_ => $natoms[$_] } 0..$#natoms  ); 

    # special csae: 
    # all atoms of element has been removed 
    my @zeroes = grep { $natoms[$_] == 0  } 0..$#natoms; 

    # remove corresponding entries
    $self->delete_natom  ( @zeroes ); 
    $self->delete_element( @zeroes ); 
} 

sub _constraint ( $self ) { 
    my @tags = $self->get_constraints;  

    # first three elements is the constraint tag 
    my @constraints = splice @tags, 0, 3;  

    # if no furthur indices are specified, 
    # replace constraint tags of all indices 
    my @indices = 
        @tags == 0 ? 
        $self->get_coordinate_indices :  
        map $_ - 1, grep $self->has_coordinate($_), @tags; 

    # set constraint 
    $self->set_dynamics_tag( map { $_ => [ @constraints ] } @indices ) 
} 

sub _parse_file ( $self ) { 
    my $poscar = {}; 

    my $fh = IO::KISS->new( $self->file, 'r' ); 
    
    # lattice vector 
    $poscar->{comment} = $fh->get_line; 
    $poscar->{scaling} = $fh->get_line; 
    $poscar->{lattice}->@* = map [ split ' ', $fh->get_line ], 0..2; 

    # natom and element 
    my ( @natoms, @elements ); 
    my @has_VASP5 = split ' ', $fh->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar->{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        @elements = VASP::POTCAR->new()->get_elements;  
        @natoms   = @has_VASP5;  
        @elements = splice @elements, 0, scalar(@natoms); 
    } else { 
        $poscar->{version} = 5; 
        @elements = @has_VASP5; 
        @natoms   = split ' ', $fh->get_line;  
    } 

    # turns @elements and @natoms into HashRef
    $poscar->{element} = { %elements[ 0..$#elements ] }; 
    $poscar->{natom  } = { %natoms[ 0..$#natoms ] }; 

    # selective dynamics 
    my $has_selective = $fh->get_line;  
    if ( $has_selective =~ /^\s*S/i ) { 
        $poscar->{selective} = 1; 
        $poscar->{type}      = $fh->get_line; 
    } else { 
        $poscar->{selective} = 0; 
        $poscar->{type}      = $has_selective; 
    } 

    # coodinate and constraint
    my ( @coordinates, @dynamics_tags );  
    while ( local $_ = $fh->get_line ) { 
        # blank line separate geometry and velocity blocks
        last if /^\s+$/; 
        
        my @columns = split; 
        # 1st 3 columns are coordinate 
        push @coordinates, [ splice @columns, 0, 3 ];  

        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        push @dynamics_tags, ( 
            @columns == 0 || @columns == 1 ? 
            [ qw( T T T ) ] :
            [ splice @columns, 0, 3 ]
        ); 
    } 

    # turns @coordinates and @dynamics into HashRef 
    $poscar->{coordinate}   = { %coordinates[ 0..$#coordinates ] }; 
    $poscar->{dynamics_tag} = { %dynamics_tags[ 0..$#dynamics_tags ] }; 

    # close fh 
    $fh->close; 

    return $poscar; 
} 

__PACKAGE__->meta->make_immutable;

1; 
