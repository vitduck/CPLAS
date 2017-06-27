#!/usr/bin/env perl 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::GSL::INTERP; 
use PDL::Stats::Basic; 

use VASP::TBdyn::Report; 
use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Slowgrowth; 

# PDL piddle
my ( $cc, $z_12, $z_12xlGkT, $z_12xEpot ); 
my ( $gradient, $free_ene ); 

read_report       ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot ); 
get_gradient      ( \$z_12, \$z_12xlGkT, \$gradient ); 
integ_slow_growth ( \$cc, \$gradient, \$free_ene ); 
write_slow_growth ( \$cc, \$gradient, \$free_ene, 'slow_growth.dat' ); 
plot_slow_growth  ( \$cc, \$gradient, \$free_ene ); 
