package Gnuplot; 

use strict; 
use warnings; 

use Exporter; 

use Util qw( read_file ); 

our @ISA         = qw( Exporter );  
our @EXPORT      = ();  
our @EXPORT_OK   = qw( read_output_eps ); 
our %EXPORT_TAGS = (); 

# read the output eps from gnuplot script 
# args 
# -< gnuplot script 
# return 
# -> output eps 
sub read_output_eps { 
    my ( $script ) = @_; 

    my $eps; 
    for ( read_file($script) ) { 
        if ( /(?<!#)set\s*output\s*"(\w+\.eps)"/ ) { $eps = $1 }
    }
    
    return $eps; 
}

1; 
