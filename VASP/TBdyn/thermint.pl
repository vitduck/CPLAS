#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use Data::Printer; 

use IO::KISS; 

use VASP::TBdyn::Thermo; 
use VASP::TBdyn::Internal; 
use VASP::TBdyn::Entropy;
use VASP::TBdyn::Helmholtz; 

# PDL piddle
my ( $cc, $gradient, $dU, $dA, $TdS);  
my ( $gradient_var, $dU_var, $dA_var, $TdS_var );  

# data preparation 
collect_data('blocked_grad.dat', 'pmf.dat' ) unless -e 'pmf.dat';  
collect_data('blocked_pot.dat',  'epot.dat') unless -e 'epot.dat'; 

# free energy 
read_data   ( 'pmf.dat', \$cc, \$gradient, \$gradient_var ); 
integ_trapz ( \$cc, \$gradient, \$gradient_var, \$dA, \$dA_var ); 
print_thermo( \$cc, \$dA, \$dA_var, 'dA.dat' );  
plot_thermo ( \$cc, \$dA, \$dA_var, 'Free Energy', 'red' ); 

# potential 
read_data   ( 'epot.dat', \$cc, \$dU, \$dU_var ); 
shift_epot  ( \$dU ); 
print_thermo( \$cc, \$dU, \$dU_var, 'dU.dat' );  
plot_thermo ( \$cc, \$dU, \$dU_var, 'Internal Energy', 'blue' ); 

# entropy 
entropy     ( \$dA, \$dU, \$TdS, \$dA_var, \$dU_var, \$TdS_var ); 
print_thermo( \$cc, \$TdS, \$TdS_var, 'TdS.dat' );  
