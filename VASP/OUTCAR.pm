package VASP::OUTCAR; 

use Moose;  
use MooseX::Types::Moose qw( Str );  
use namespace::autoclean; 

use Try::Tiny; 
use PDL::Lite; 
use IO::KISS; 
use VASP::POSCAR;  

use experimental qw( signatures ); 

with qw( IO::Reader ); 
with qw( VASP::Force Regex::OUTCAR ); 

has 'file', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1, 
    default   => 'OUTCAR' 
); 

has 'poscar_indices', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { VASP::POSCAR->new },  

    handles   => [ 
        qw( 
            get_true_indices
            get_false_indices 
        )
    ]
); 

# from IO::Reader
sub _build_reader ( $self ) { 
    return IO::KISS->new( $self->file, 'r' ) 
}

# VASP::Force
# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @forces, @true_indices, @false_indices ); 

    # cache POSCAR if possible 
    try { 
        @true_indices  = $self->get_true_indices; 
        @false_indices = $self->get_false_indices  
    } 

    # cannot read POSCAR 
    catch { 
        @false_indices == 0 
    }; 

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

__PACKAGE__->meta->make_immutable;

1 
