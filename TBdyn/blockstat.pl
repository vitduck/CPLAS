#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Report; 
use Gradient; 
use Statistics; 

# bluemoon data
my ( $cc, $z_12, $lpGkT, $e_pot ); 

# block statistic  
my ( $bsize, $bavg, $bstdv, $bstde ); 

read_report  ( \$cc, \$z_12, \$lpGkT, \$e_pot ); 
block_average( \$z_12,  \$lpGkT, \$bsize, \$bavg, \$bstdv, \$bstde ); 
write_stderr ( \$cc, \$bsize, \$bavg, \$bstdv, \$bstde => 'blocked_gradient.dat' );  
plot_stderr  ( \$cc, \$bsize, \$bstde, 'Gradient' ); 
block_average( \$z_12, \$e_pot, \$bsize, \$bavg, \$bstdv, \$bstde ); 
write_stderr ( \$cc, \$bsize, \$bavg, \$bstdv, \$bstde => 'blocked_potential.dat' );  
plot_stderr  ( \$cc, \$bsize, \$bstde, 'Potential' ); 
