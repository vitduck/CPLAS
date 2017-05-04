#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Gradient; 
use Plot; 

my ( $cc, $z_12, $lpGkT, $gradient   ); 
my ( $moving_index, $moving_gradient ); 

read_report    ( \$cc, \$z_12, \$lpGkT ); 
get_gradient   ( \$z_12, \$lpGkT, \$gradient );  
acc_gradient   ( \$cc, \$z_12, \$lpGkT, \$moving_index, \$moving_gradient ); 
write_igradient( \$gradient => 'igradient.dat' ); 
write_agradient( \$moving_index, \$moving_gradient => 'agradient.dat' );  
plot_gradient  ( \$cc, \$gradient, \$moving_index, \$moving_gradient );  
