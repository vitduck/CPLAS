package VASP::OUTCAR::Force;  

use Moose::Role;  
use MooseX::Types::Moose qw/RegexpRef/;  
use IO::KISS; 
use VASP::POSCAR; 
use PDL::Lite; 
use Try::Tiny; 

use namespace::autoclean; 
use experimental 'signatures';  

with 'General::Force'; 

has '_POSCAR', ( 
    is        => 'ro', 
    isa       => 'VASP::POSCAR',   
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub { VASP::POSCAR->new },  
    handles   => [ qw/get_true_indices get_false_indices/ ] 
); 

# TODO: is it possible to capture the final three columns 
#       without explicit split
has '_force_regex', ( 
    is        => 'ro', 
    isa       => RegexpRef, 
    init_arg  => undef, 
    lazy      => 1, 
    default   => sub { 
        qr/
            (?:
                \ POSITION\s+TOTAL-FORCE\ \(eV\/Angst\)\n
                \ -+\n
            )
            (.+?) 
            (?: 
                \ -+\n
            )
        /xs 
    } 
); 

# perform regex in list context 
# open FH to force block string and iterate over each line 
# The 3,4, and 5 column are fx, fy, and fz 
# @forces is a 3d matrix with dimension of NSW x NIONS x 3
sub _build_force ( $self ) { 
    my ( @forces, @true_indices, @false_indices ); 

    try { 
        @true_indices  = $self->get_true_indices;
        @false_indices = $self->get_false_indices  
    } 
    
    catch { 
        @false_indices = ()  
    }; 

    for ( $self->slurp =~ /${ \$self->_force_regex }/g ) { 
        my @iforces;  

        for ( IO::KISS->new( \$_, 'r' )->get_lines ) { 
            push @iforces, [ ( split )[ 3..5 ] ]
        }

        push @forces, \@iforces; 
    }

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

1 
