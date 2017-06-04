#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Potential; 
use Statistics; 

# PDL piddle
my ( $z_12, $e_pot ); 
my ( $bsize, $bavg, $bstdv, $bstde ); 

read_potential( \$z_12, \$e_pot );  
block_average ( \$z_12, \$e_pot, \$bsize, \$bavg, \$bstdv, \$bstde ); 
write_stderr  ( \$bsize, \$bavg, \$bstdv, \$bstde => 'blocked_potential.dat' );  
