#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use IO::KISS; 

use Data::Printer; 

use VASP::TBdyn::Report; 
use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Statistics; 

my $dir_in  = shift @ARGV; 

# read list of directory from input files
chomp ( my @dirs = 
    $dir_in ?  
    IO::KISS->new( $dir_in, 'r' )->get_lines : 
    qw( . ) 
); 

my $top_dir = $ENV{PWD}; 

for my $dir ( @dirs ) { 
    print "\n=> Processing: $dir\n" unless $dir eq '.';  

    chdir $dir; 

    # bluemoon data
    my ( $cc, $z_12 );  
    my ( $z_12xlGkT, $grad_bsize, $grad_bvar, $grad_SI ); 
    my ( $z_12xEpot, $epot_bsize, $epot_bvar, $epot_SI );  

    # parse REPORT 
    read_report   ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot, 1000 ); 

    # gradient 
    block_analysis( \$z_12xlGkT, \$grad_bsize, \$grad_bvar, \$grad_SI );  
    plot_SI       ( \$cc, \$grad_bsize, \$grad_SI, 'grad' );  
    write_SI      ( \$grad_bsize, \$grad_bvar, \$grad_SI => 'SI_grad.dat' ); 
    coarsed_grain ( \$cc, \$z_12, \$z_12xlGkT => 'CS_grad.dat' ); 
    
    # potential 
    block_analysis( \$z_12xEpot, \$epot_bsize, \$epot_bvar, \$epot_SI );  
    plot_SI       ( \$cc, \$epot_bsize, \$epot_SI, 'epot' );  
    write_SI      ( \$epot_bsize, \$epot_bvar, \$epot_SI => 'SI_epot.dat' ); 
    coarsed_grain ( \$cc, \$z_12, \$z_12xEpot => 'CS_epot.dat' ); 
   
    # return 
    chdir $top_dir; 
} 
