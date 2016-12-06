#!/usr/bin/env perl 

use strict; 
use warnings; 
use feature qw/switch/;  
use experimental qw/smartmatch/;  

use VASP::POTCAR; 

# init
my $potcar = VASP::POTCAR->new_with_options; 

# parse cmd 
my ( $mode, @elements ) = $potcar->argv; 

# set POTCAR's elements
$potcar->add_element( @elements ); 

given ( $mode //= 'default' ) {
    when ( 'append' ) { $potcar->append } 
    when ( 'make'   ) { $potcar->make   }
    default           { $potcar->help   }  
} 
