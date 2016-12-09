#!/usr/bin/env perl 

use strict; 
use warnings; 

use VASP::POTCAR; 
use Data::Printer; 

my $potcar = VASP::POTCAR->new_with_options; 
