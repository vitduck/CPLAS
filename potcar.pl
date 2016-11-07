#!/usr/bin/env perl 

use strict; 
use warnings; 
use feature qw( switch );   
use experimental qw( smartmatch );  

use VASP::POTCAR; 

my $potcar = VASP::POTCAR->new_with_options; 

my ( $mode, @elements ) = $potcar->argv; 

# set POTCAR elements 
$potcar->add_element( @elements ) if @elements; 

given ( shift @ARGV // 'default' ) {
    when ( 'info'   ) { $potcar->info                }
    when ( 'append' ) { $potcar->append( @elements ) } 
    when ( 'make'   ) { $potcar->make                }
    default           { print $potcar->getopt_usage  }  
} 
