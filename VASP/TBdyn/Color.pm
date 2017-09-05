package VASP::TBdyn::Color;  

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

our @ISA    = qw( Exporter ); 
our @EXPORT = qw( %hcolor  ); 

our %hcolor = ( 
    blue   => '#94bff3',  
    cyan   => '#8cd0d3',
    green  => '#60b48a',
    red    => '#cc9393', 
    yellow => '#dfaf8f',
    white  => '#dcdccc',
); 

1
