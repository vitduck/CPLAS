!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use TBdyn; 
use Data::Printer; 

my ( %gradient, %trapz, %spline ); 

read_gradients( shift @ARGV // 'gradients.dat', \%gradient ); 
trapezoidal   ( \%gradient, \%trapz ); 
shift_hash    ( \%trapz, -1 ); 
print_hash    ( \%trapz => 'test.dat' ); 
cspline       ( \%trapz, \%spline ); 
minima        ( \%spline ); 
plot_free_ene ( \%trapz, \%spline ); 
