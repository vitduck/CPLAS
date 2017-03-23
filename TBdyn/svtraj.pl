#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Data::Printer;  
use File::Path 'make_path'; 
use File::Copy 'copy';  
use List::Util 'max'; 

my @files   = qw/INCAR POSCAR KPOINTS CONTCAR OSZICAR XDATCAR OUTCAR REPORT/;  

create_history(); 
log_history();  


sub create_history { 
    make_path( 'history' ) unless -d 'history'; 
} 

sub log_history { 
    my $latest = latest_index(); 
    my @exists = grep -e , @files;  
    my $date   = join '-', ( split ' ', `date` )[1,2,-1]; 

    system 'tar', 'cvzf', "history/${latest}-${date}.tar.gz", @exists; 
} 

sub latest_index { 
    my @indices = ();  
    
    for ( <history/*> ) { 
        #push @indices, $1 if /(\d+)/ 
        push @indices, $1 if /(\d+)\-.*.tar.gz/ 
    }

    return 
        @indices 
        ? 1 + max( @indices )
        : 1
}

# sub save_trajectory { 
    # my $latest = latest_index(); 
    
    # copy $_ => "history/$latest.$_" for @files; 
# } 
