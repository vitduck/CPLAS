package VASP::Force; 

# cpan 
use PDL::Lite; 
use Moose::Role; 
use MooseX::Types::Moose qw//; 
use namespace::autoclean; 

# pragma
use warnings FATAL => 'all'; 
use experimental qw/signatures/;  

# Moose class 
use VASP::POSCAR;  
use IO::KISS; 

with 'VASP::Regex'; 

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
    }, 
); 

#----------------#
# Private Method #
#----------------#
sub _build_force ( $self ) { 
    my @indices = VASP::POSCAR->new->get_true_indices;  
    
    # perform regex in list context 
    # open FH to force block string and iterate over each line 
    # The 3,4, and 5 column are fx, fy, and fz 
    # @forces is a 3d matrix with dimension of NSW x NIONS x 3
    my @forces  = ();  
    for my $force_block ( $self->slurp =~ /${\$self->force_regex}/g  ) { 
        my $kiss    =  IO::KISS->new(\$force_block, 'r'); 
        my @iforces = (); 
        for ( $kiss->get_lines ) { 
            push @iforces, [ (split)[3,4,5] ]; 
        } 
        push @forces, \@iforces; 
    } 
    
    return PDL->new(@forces)->dice( 'X', \@indices, 'X' ); 
} 

sub _build_max_force ( $self ) { 
    # Dimensions of PDL piddle is reversed w.r.t standard matrix notation 
    # Dimension of the force 3d matrix is: 3 x NIONS x NSW ( instead of NSW x NIONS x 3 )
    # However, this facilitate dimensional reduction operator as following: 
    return ( $self->force * $self->force )->sumover->sqrt->maximum; 
} 

1; 
