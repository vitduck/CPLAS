package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  
use Try::Tiny; 
use PDL::Lite; 
use IO::KISS; 

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( 
    IO::Reader 
    VASP::Force 
    Regex::Force 
); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

has 'POSCAR', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => '_build_POSCAR', 
    handles   => [ qw( get_true_indieces get_false_indices ) ]
); 

# from IO::Reader
sub _build_reader ( $self ) { return IO::KISS->new( $self->file, 'r' ) }

# VASP::Force
# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @true_indices, @false_indices ); 

    # cache POSCAR if possible 
    try { 
        @true_indices  = $self->get_true_indices; 
        @false_indices = $self->get_false_indices  
    } 
    # cannot read POSCAR 
    catch { 
        @false_indices == 0 
    }; 

    # regex in list context
    my @fblocks = ( $self->slurp =~ /${\$self->force_regex}/g );  
    
    # double mapping 
    my @forces  = 
        map [
            map [ 
                ( split )[ 3..5 ] 
            ], IO::KISS->new( \$_, 'r' )->get_lines 
        ], @fblocks ;  

    return 
        @false_indices == 0 
        ? PDL->new( \@forces ) 
        : PDL->new( \@forces )->dice( 'X', \@true_indices, 'X' ) 
} 

__PACKAGE__->meta->make_immutable;

# native 
sub _build_POSCAR ( $self ) { 
    return VASP::POSCAR->new 
}

1 
