#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Report; 

my ( $cc, $z_12, $lpGkT, $e_pot, $gradient ); 
my ( $moving_index, $moving_gradient ); 

read_report       ( \$cc, \$z_12, \$lpGkT, \$e_pot, 0 ); 
get_gradient      ( \$z_12, \$lpGkT, \$gradient );  
get_avg_gradient  ( \$cc, \$z_12, \$lpGkT, \$moving_index, \$moving_gradient ); 
write_gradient    ( \$gradient => 'igradient.dat' ); 
write_avg_gradient( \$moving_index, \$moving_gradient => 'agradient.dat' );  
plot_gradient     ( \$cc, \$gradient, \$moving_index, \$moving_gradient );  
