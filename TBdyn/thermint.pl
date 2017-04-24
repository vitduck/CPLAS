#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use TBdyn; 
use Data::Printer; 

my ( %pmf, %trapz, %spline ); 

read_pmf      ( \%pmf ); 
trapezoidal   ( \%pmf, \%trapz ); 
print_free_ene( \%trapz => 'free_ene.dat' ); 
cspline       ( \%trapz, \%spline ); 
print_cspline ( \%spline => 'cspline.dat' ); 
plot_free_ene ( \%trapz, \%spline ); 
