package Plot; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( %color ); 

our %color = ( 
    red  => "#cc9393", 
    blue => "#94bff3",  
); 

1
