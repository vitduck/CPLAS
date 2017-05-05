#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Pmf; 

# PDL piddle
my ( $cc, $gradient, $variance ); 
my ( $free_ene, $prop_err ); 

read_pmf      ( 'pmf.dat', \$cc, \$gradient, \$variance ); 
integ_trapz   ( \$cc, \$gradient, \$variance, \$free_ene, \$prop_err ); 
print_free_ene( \$cc, \$free_ene, \$prop_err, 'free_ene.dat' );  
plot_free_ene ( \$cc, \$free_ene, \$prop_err ); 
