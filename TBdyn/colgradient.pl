#!/usr/bin/env perl 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use TBdyn;  

my %gradient; 

read_gradient( \%gradient ); 
print_hash   ( \%gradient => 'gradients.dat' ); 
