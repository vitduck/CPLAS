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
    predicate => 'has_delete_tag', 

    handles   => {  
        get_delete_tag => 'elements' 
    } 
); 

has 'dynamics', (   
    is        => 'ro', 
    isa       => ArrayRef, 
    traits    => [ 'Array' ], 
    predicate => 'has_dynamics_tag', 
    
    handles   => {  
        get_dynamics_tag => 'elements' 
    } 
); 

has 'backup', ( 
    is        => 'ro', 
    isa       => Str, 
    predicate => 'has_backup_tag', 
); 

has 'save_as', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    predicate => 'has_save_as_tag',  
    default => 'POSCAR.new', 
); 

sub _backup ( $self ) { 
    copy $self->file => $self->backup
} 

sub _delete ( $self ) { 
    # off-set indies 
    my @indices = 
        map $_ - 1, 
        grep $self->has_index($_), 
        $self->get_delete_tag; 

    # delte corresponding constraint and coordinate 
    $self->delete_index     ( @indices ); 
    $self->delete_coordinate( @indices ); 
    $self->delete_constraint( @indices ); 
    
    # private synchornization 
    # $self->_update_natom_and_element; 
} 

# sub _update_natom_and_element ( $self, @indices ) { 
    # # debug 
    # use Data::Printer; 
    
    # # construct the boundaries 
    # # Ex: @natom = ( 10, 20, 40 ) -> @boundaries = ( 10, 30, 70 )
    # my $bound      = 0; 
    # my @boundaries = (); 
    # push @boundaries, ( $bound += $_ ) for $self->get_natoms; 
    
    # # cache natom 
    # my @natoms = $self->get_natoms; 
    # for my $delete ( $self->get_delete_tag ) { 
        # # takes the lower bound only 
        # my ( $index )    = grep { $delete <= $boundaries[$_] } 0..$#boundaries;  
        # $natoms[$index] -= 1; 
    # } 

    # # now update the original natom and element 
    # $self->set_natom( $_ => $natoms[$_] ) for  0..$#natoms; 

    # # special case: all the atom of element is removed 
    # my @zero_indices = grep $natoms[$_] == 0, 0..$#natoms; 
# } 

sub _dynamics ( $self ) { 
    my @dynamics = $self->get_dynamics_tag;  

    # first three elements is the constraint tag 
    my @new_constraint = splice @dynamics, 0, 3;  

    # if no furthur indices are specified, 
    # replace constraint tags of all indices 
    my @indices = 
        @dynamics == 0 ? 
        $self->get_indices :  
        map $_ - 1, grep $self->has_index($_), @dynamics;  

    # set new constraint 
    $self->set_constraint( map { $_ => [ @new_constraint ] } @indices ) 
} 

sub _parse_file ( $self ) { 
    my $poscar = {}; 

    my $fh = IO::KISS->new( $self->file, 'r' ); 
    
    # geometry 
    $poscar->{comment} = $fh->get_line; 
    $poscar->{scaling} = $fh->get_line; 
    $poscar->{lattice}->@* = map [ split ' ', $fh->get_line ], 0..2; 

    # version probe
    my @has_VASP5 = split ' ', $fh->get_line; 
    if ( ! grep Element->check($_), @has_VASP5 ) { 
        $poscar->{version} = 4; 
        # get elements from POTCAR and synchronize with @natoms
        $poscar->{element} = [ VASP::POTCAR->new()->get_elements ]; 
        $poscar->{natom}   = \@has_VASP5;  
        $poscar->{element}->@* = splice $poscar->{element}->@*, 0, $poscar->{natom}->@*; 
    } else { 
        $poscar->{version} = 5; 
        $poscar->{element} = \@has_VASP5; 
        $poscar->{natom}   = [ split ' ', $fh->get_line ]; 
    } 

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
    my $index = 0;   
    while ( local $_ = $fh->get_line ) { 
        # separation between geometry and velocity blocks
        last if /^\s+$/; 
        
        # build the index 
        $poscar->{index}->{$index} = $index; 

        my @columns = split; 
        # 1st 3 columns are coordinate 
        $poscar->{coordinate}->{$index} = [ splice @columns, 0, 3 ];  

        # if remaining column is either 0 or 1 (w/o indexing) 
        # the POSCAR contains no selective dynamics block 
        $poscar->{constraint}->{$index} = (
            @columns == 0 || @columns == 1 ? 
            [ qw/T T T/ ] :
            [ splice @columns, 0, 3 ]
        ); 

        $index++; 
    } 

    $fh->close; 

    return $poscar; 
} 

sub BUILD ( $self, @args ) { 
    # cache POSCAR
    try { $self->parser };  

    # processing tags 
    $self->_backup   if $self->has_backup_tag;  
    $self->_delete   if $self->has_delete_tag; 
    $self->_dynamics if $self->has_dynamics_tag; 
} 

sub write ( $self ) { 
    # if save_as is not set, overwrite the original POSCAR 
    my $fh = 
        $self->has_save_as_tag ? 
        IO::KISS->new( $self->save_as, 'w' ) :  
        IO::KISS->new( $self->file, 'w' ); 

    # constructing geometry block 
    # the indices must be sorted in numerical order 
    # since they are keys of hash ( pseudo random )
    my @indices = sort { $a <=> $b } $self->get_indices; 
    my @table = 
        $self->selective ? 
        map [ $self->get_coordinate($_)->@*, $self->get_constraint($_)->@*, $_+1 ], @indices : 
        map [ $self->coordinate->[$_]->@*, $_+1 ], @indices; 

    # write to POSCAR 
    $fh->printf( "%s\n", $self->comment ); 
    $fh->printf( $self->get_format( 'scaling' ), $self->scaling ); 
    $fh->printf( $self->get_format( 'lattice' ), @$_) for $self->get_lattices;  
    $fh->printf( $self->get_format( 'element' ), $self->get_elements ) if $self->version == 5;  
    $fh->printf( $self->get_format( 'natom'   ), $self->get_natoms ); 
    $fh->printf( "%s\n", 'Selective Dynamics' )  if $self->selective;  
    $fh->printf( "%s\n", $self->type ); 
    $fh->printf( $self->get_format( 'coordinate' ), @$_ ) for @table; 
    
    $fh->close; 
} 

__PACKAGE__->meta->make_immutable;

1; 
