#!/usr/bin/env perl 

use strict; 
use warnings; 

use VASP::Force; 

my $force = VASP::Force->new_with_options;  

$force->print_forces; 
