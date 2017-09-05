package VASP::TBdyn::Helmholtz; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use IO::KISS;  

our @ISA    = qw( Exporter  );  
our @EXPORT = qw( helmholtz ); 

# trapezoidal integration
sub helmholtz ( $cc, $gradient, $variance, $dA, $dA_var ) { 
    my ( @free_enes, @prop_errs ); 

    # reference point 
    $free_enes[0] = 0; 
    $prop_errs[0] = 0; 

    # Trapezoidal integration
    # Ref: T. Bucko, Journal of Cataylysis (2007)
    for my $i ( 1 .. $$cc->nelem - 1 ) { 
        # first and last point
        $free_enes[$i] = 
            0.50 * $$gradient->at(0)  * ( $$cc->at(1)  - $$cc->at(0)    ) + 
            0.50 * $$gradient->at($i) * ( $$cc->at($i) - $$cc->at($i-1) ); 

        $prop_errs[$i] = 
            0.25 * $$variance->at(0)  * ( $$cc->at(1)  - $$cc->at(0)    )**2 + 
            0.25 * $$variance->at($i) * ( $$cc->at($i) - $$cc->at($i-1) )**2; 
            
        # middle point with cancellation
        for my $j ( 1..$i - 1 ) { 
            $free_enes[$i] += 
                0.50 * $$gradient->at($j) * ( $$cc->at($j+1) - $$cc->at($j-1) ); 
            
            $prop_errs[$i] += 
                0.25 * $$variance->at($j) * ( $$cc->at($j+1) - $$cc->at($j-1) )**2 
        } 
    }

    # deref PDL piddle 
    $$dA     = PDL->new( @free_enes );  
    $$dA_var = PDL->new( @prop_errs ); 
}

1
