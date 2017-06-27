package VASP::TBdyn::Color;  

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( %hcolor ); 

our %hcolor = ( 
    white => '#dcdccc',
    red   => '#cc9393', 
    blue  => '#94bff3',  
    green => '#60b48a',
); 

1
