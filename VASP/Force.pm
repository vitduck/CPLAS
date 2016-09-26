package VASP::Force; 

use Try::Tiny; 
use PDL::Lite; 

use Moose::Role; 
use IO::KISS; 

use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( slurp force_regex ); 

has 'force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 
    builder  => '_build_force', 
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_max_force', 
    handles   => { 
        get_max_forces => 'list' 
    } 
); 

# native 
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
    my @forces  = map [ 
        map [ ( split )[3,4,5] ], IO::KISS->new( \$_, 'r' )->get_lines 
    ], @fblocks; 

    return 
        @false_indices == 0 
        ? PDL->new( \@forces ) 
        : PDL->new( \@forces )->dice( 'X', \@true_indices, 'X' ) 
} 

# Dimensions of PDL piddle is reversed w.r.t standard matrix notation 
# Dimension of the force 3d matrix is: 3 x NIONS x NSW ( instead of NSW x NIONS x 3 )
# However, this facilitate dimensional reduction operator as following: 
sub _build_max_force ( $self ) { 
    return ( $self->force * $self->force )->sumover->sqrt->maximum; 
} 

1; 
