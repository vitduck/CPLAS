package Fortran;  

use strict; 
use warnings; 

use Exporter; 

our @format = qw(fortran2perl); 

our @ISA         = qw(Exporter);  
our @EXPORT      = ();  
our @EXPORT_OK   = (@format); 
our @EXPORT_TAGS = (); 

# fortran-like format => perl format
# crude implementation 
# args 
# -< fortran simple format  
# return 
# -> perl equivalent format
sub fortran2perl {  
    my ($format) = @_; 

    my $perl; 
    my @fortran = ( $format =~ /(\d*)%([-0-9.]*[deEfs])/g ); 

    while (@fortran) { 
        # empty repition == 1
        my $rep    = shift @fortran || 1; 
        my $format = shift @fortran; 
        #$perl     .= (join ' ', ("%$format")x$rep).' ';  
        $perl     .= "%$format"x$rep; 
    }
    
    return $perl; 
}

# last evaluated expression 
1; 
