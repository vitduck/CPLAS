#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Data::Printer;  
use File::Path qw( make_path ); 
use File::Copy qw( copy ); 
use List::Util qw( max ); 

my @files   = qw( POSCAR CONTCAR XDATCAR OUTCAR REPORT ); 

create_history(); 
save_trajectory(); 

sub save_trajectory { 
    my $latest = latest_index(); 
    copy $_ => "history/$latest.$_" for @files; 
} 

sub latest_index { 
    my @indices = ();  
    
    for ( <history/*> ) { 
        push @indices, $1 if /(\d+)/ 
    }

    return 
        @indices 
        ? 1 + max( @indices )
        : 1
}

sub create_history { 
    make_path('history') unless -d 'history'; 
} 
