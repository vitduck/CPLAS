#!/usr/bin/env perl 

use strict; 
use warnings; 
use feature 'switch'; 
use experimental 'smartmatch'; 

use VASP::POTCAR; 

my $potcar = VASP::POTCAR->new_with_options; 

given ( my $mode = $potcar->get_arg // '' ) {
    when ( 'info' )                         { $potcar->info                 }
    when ( /make|add|remove|order|select/ ) { $potcar->$mode; $potcar->info }
    default                                 { $potcar->help                 }  
}
