package VASP::TBdyn::Internal; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use Data::Printer; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    shift_epot
);  

sub shift_epot ( $epot ) { 
    $$epot = $$epot - $$epot->at(0); 
} 

1 
