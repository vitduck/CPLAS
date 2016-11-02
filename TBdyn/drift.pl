#!/usr/bin/env perl 

use strict; 
use warnings; 

use TBdyn;  
use Data::Printer output => 'stdout'; 

my ( %energy, %spline ); 

pes          ( \%energy);  
shift_hash   ( \%energy, -1 ); 
cspline      ( \%energy, \%spline ); 
print_hash   ( \%energy => 'pes.dat' ); 
print_hash   ( \%spline => 'cspline.dat' ); 
minima       ( \%spline ); 
plot_free_ene( \%energy, \%spline ); 
