#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use VASP::TBdyn::Report; 
use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Internal; 
use VASP::TBdyn::Statistics; 

my ( $cc, $z_12, $z_12xlGkT, $z_12xEpot );
my ( $grad, $epot ); 

read_report  ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot ); 
unbiased_avg ( \$z_12, \$z_12xlGkT, \$grad => 'grad_avg.dat' ); 
unbiased_avg ( \$z_12, \$z_12xEpot, \$epot => 'epot_avg.dat' ); 
pl_grad_avg  ( \$cc, \$grad ); 
pl_epot_avg  ( \$cc, \$epot ); 
