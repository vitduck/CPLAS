#!/usr/bin/env perl 

use strict; 
use warnings; 
use feature qw( switch );   
use experimental qw( smartmatch );  

use VASP::POTCAR; 

my $potcar = VASP::POTCAR->new_with_options; 

$potcar->getopt_usage( exit => 1 ) if @ARGV == 0; 

given ( shift @ARGV // 'default' ) { 
    when ( 'info'   ) { $potcar->info                                            }
    when ( 'append' ) { $potcar->append( $potcar->get_elements ); $potcar->info  } 
    when ( 'make'   ) { $potcar->make                                            }
    default           { print $potcar->getopt_usage                              }  
} 
