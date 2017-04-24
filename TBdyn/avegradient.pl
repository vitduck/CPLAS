#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Gradient; 
use Plot; 

my ( $cc, $bm, $igrad, $agrad ); 

read_report( \$cc, \$bm ); 
get_igrad  ( \$bm, \$igrad );  
get_agrad  ( \$bm, \$agrad ); 
get_mgrad  ( \$cc, \$bm ); 
write_grad ( \$igrad => 'igrad.dat' ); 
write_grad ( \$agrad => 'agrad.dat' ); 
plot_grad  ( \$cc, \$igrad, \$agrad ); 
