package VASP::Force; 

use PDL::Lite; 
use Moose::Role; 

use strictures 2; 
use namespace::autoclean; 
use experimental qw/signatures/;  

use IO::KISS; 
use VASP::POSCAR;  

requires /slurp force-regex/;  

has 'force', ( 
    is       => 'ro', 
    isa      => 'PDL', 
    init_arg => undef, 
    lazy     => 1, 

    # perform regex in list context 
    # open FH to force block string and iterate over each line 
    # The 3,4, and 5 column are fx, fy, and fz 
    # @forces is a 3d matrix with dimension of NSW x NIONS x 3
    default  => sub ( $self ) { 
        my $force = [];  
        my $true  = VASP::POSCAR->new->true_index; 

        for my $force_block ( $self->slurp =~ /${\$self->force_regex}/g  ) { 
            my $iforce = []; 
            my $kiss   = IO::KISS->new(\$force_block, 'r'); 
            for ( $kiss->get_lines ) { 
                push $iforce->@*, [ (split)[3,4,5] ]; 
            } 
            push $force->@*, $iforce; 
        } 
        return PDL->new($force)->dice( 'X', $true, 'X' ); 
    }, 
); 

has 'max_force', ( 
    is        => 'ro', 
    isa       => 'PDL', 
    init_arg  => undef, 
    lazy      => 1, 
    
    # Dimensions of PDL piddle is reversed w.r.t standard matrix notation 
    # Dimension of the force 3d matrix is: 3 x NIONS x NSW ( instead of NSW x NIONS x 3 )
    # However, this facilitate dimensional reduction operator as following: 
    default   => sub ( $self ) { 
        return ( $self->force * $self->force )->sumover->sqrt->maximum; 
    },  

    handles   => { 
        get_max_forces => 'list' 
    }, 
); 

1; 
