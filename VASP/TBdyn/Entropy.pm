package VASP::TBdyn::Entropy; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use Data::Printer; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    entropy
);  

sub entropy ( $dA, $dU, $TdS, $dA_var, $dU_var, $TdS_var ) { 
    # sanity check
    die "Something is serious wrong ... with your brain\n" unless $$dA->nelem == $$dU->nelem; 

    # TdS = dU - dA
    $$TdS     = $$dU - $$dA;  
    $$TdS_var = $$dU_var + $$dA_var
} 

1 
