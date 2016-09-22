package VASP::Force; 

use Moose::Role; 
use Try::Tiny; 
use PDL::Lite; 
use IO::KISS; 
use VASP::POSCAR;  
use namespace::autoclean; 
use experimental qw( signatures ); 

has 'force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 
    builder  => '_build_force' 
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_max_force', 
    handles   => { get_max_forces => 'list' } 
); 

#---------# 
# BUILDER #
#---------# 
# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @forces, @true_indices, @false_indices ) = ();   

    try { 
        my $poscar = VASP::POSCAR->new;  
        @true_indices  = $poscar->get_true_indices; 
        @false_indices = $poscar->get_false_indices; 
    } 
    # POSCAR does not exist 
    catch { @false_indices == 0 } ; 

    for my $force_block ( $self->slurp =~ /${\$self->force_regex}/g  ) { 
        my @iforces = (); 
        my $kiss    = IO::KISS->new(\$force_block, 'r'); 
        for ( $kiss->get_lines ) { 
            push @iforces, [ (split)[3,4,5] ]; 
        } 
        push @forces, \@iforces; 
    } 

    return (
        @false_indices == 0 ? 
        PDL->new( \@forces ) : 
        PDL->new( \@forces )->dice( 'X', \@true_indices, 'X' ) 
    )
} 

# Dimensions of PDL piddle is reversed w.r.t standard matrix notation 
# Dimension of the force 3d matrix is: 3 x NIONS x NSW ( instead of NSW x NIONS x 3 )
# However, this facilitate dimensional reduction operator as following: 
sub _build_max_force ( $self ) { 
    return ( $self->force * $self->force )->sumover->sqrt->maximum; 
} 

1; 
