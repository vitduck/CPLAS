#!/usr/bin/env perl 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::GSL::INTERP; 
use PDL::Stats::Basic; 

use IO::KISS; 

use Gradient; 
use Slowgrowth; 

# PDL piddle
my ( $cc, $z_12, $lpGkT, $gradient, $free_ene ); 

read_report      ( \$cc, \$z_12, \$lpGkT, 0 ); 
get_gradient     ( \$z_12, \$lpGkT, \$gradient );  
write_gradient   ( \$gradient => 'gradient.dat' ); 
integ_slow_growth( \$cc, \$gradient, \$free_ene ); 
write_slow_growth( \$cc, \$gradient, \$free_ene => 'slow_growth.dat' ); 
plot_slow_growth ( \$cc, \$gradient, \$free_ene ); 
