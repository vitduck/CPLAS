#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use Data::Printer; 

use IO::KISS; 

use VASP::TBdyn::Thermo; 
use VASP::TBdyn::Helmholtz; 
use VASP::TBdyn::Internal; 
use VASP::TBdyn::Entropy;

my $cc; 
my ( $grad, $dU, $dA, $TdS ); 
my ( $grad_var, $dU_var, $dA_var, $TdS_var ); 

# free energy 
read_thermo ( 'grad.dat', \$cc, \$grad, \$grad_var ); 
helmholtz   ( \$cc, \$grad, \$grad_var, \$dA, \$dA_var ); 
print_thermo( \$cc, \$dA, \$dA_var => 'dA.dat' );  
plot_thermo ( \$cc, \$dA, \$dA_var, 'dA' ); 

# potential 
read_thermo ( 'epot.dat', \$cc, \$dU, \$dU_var ); 
internal    ( \$dU ); 
print_thermo( \$cc, \$dU, \$dU_var => 'dU.dat' );  
plot_thermo ( \$cc, \$dU, \$dU_var, 'dU' ); 

# entropy 
entropy     ( \$dA, \$dU, \$TdS, \$dA_var, \$dU_var, \$TdS_var ); 
print_thermo( \$cc, \$TdS, \$TdS_var => 'TdS.dat' );  
plot_thermo ( \$cc, \$TdS, \$TdS_var, 'TdS' ); 
