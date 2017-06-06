package VASP::TBdyn::Plot; 

use autodie; 
use strict; 
use warnings; 
use experimental qw( signatures ); 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( %hcolor ); 

our %hcolor = ( 
    red  => "#cc9393", 
    blue => "#94bff3",  
); 

1
