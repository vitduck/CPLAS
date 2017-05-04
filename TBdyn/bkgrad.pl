#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Gradient; 
use Statistics; 

# PDL piddle
my ( $cc, $z_12, $lpGkT ); 
my ( $bsize, $bavg, $bstdv, $bstde ); 

read_report  ( \$cc, \$z_12, \$lpGkT ); 
block_average( \$z_12,  \$lpGkT, \$bsize, \$bavg, \$bstdv, \$bstde ); 
write_stderr ( \$bsize, \$bavg, \$bstdv, \$bstde => 'block.dat' );  
plot_stderr  ( \$cc, \$bsize, \$bstde ); 
