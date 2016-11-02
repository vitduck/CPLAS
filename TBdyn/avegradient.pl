#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use TBdyn; 

my ( $cc, @gradients, @averages );  

read_report( shift @ARGV // 'REPORT', \$cc, \@gradients );  
acc_average( \@gradients, \@averages ); 
plot_grad  ( \@gradients, \@averages );  
