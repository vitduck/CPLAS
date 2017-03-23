#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use TBdyn; 
use Data::Printer; 

my ( %pmf, %trapz, %spline ); 

read_pmf      ( \%pmf ); 
trapezoidal   ( \%pmf, \%trapz ); 
# shift_hash    ( \%trapz, -1 ); 
print_hash    ( \%trapz => 'free_ene.dat' ); 
cspline       ( \%trapz, \%spline ); 
print_hash    ( \%spline => 'cspline.dat' ); 
minima        ( \%spline ); 
plot_free_ene ( \%trapz, \%spline ); 
