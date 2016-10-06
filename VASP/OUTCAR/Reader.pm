package VASP::OUTCAR::Reader; 

use Moose::Role; 
use namespace::autoclean; 
use experimental qw( signatures );  

# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @forces, @true_indices, @false_indices ); 

    if ( -f 'POSCAR' ) {   
        # cache POSCAR if possible 
        @true_indices  = $self->get_true_indices; 
        @false_indices = $self->get_false_indices  
    } else { 
        # empty list
        @false_indices = ()  
    }

    for ( $self->_slurp =~ /${ \$self->force_regex }/g ) { 
        my @iforces;  

        for ( IO::KISS->new( \$_, 'r' )->get_lines ) { 
            push @iforces, [ ( split )[ 3, 4, 5 ] ]
        }

        push @forces, \@iforces; 
    }

    return 
        @false_indices == 0 
        ? PDL->new( \@forces ) 
        : PDL->new( \@forces )->dice( 'X', \@true_indices, 'X' ) 
} 
