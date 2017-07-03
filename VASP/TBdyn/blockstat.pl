#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Data::Printer; 

use IO::KISS; 
use VASP::TBdyn::Report; 
use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Statistics; 

my $dir_in  = shift @ARGV; 

# read list of directory from input files
chomp ( my @dirs = $dir_in ? IO::KISS->new( $dir_in, 'r' )->get_lines : qw( . ) ); 

my $top_dir = $ENV{PWD}; 

for my $dir ( @dirs ) { 
    print "\n=> Processing: $dir\n" unless $dir eq '.';  

    chdir $dir; 

    # bluemoon data
    my ( $cc, $z_12 );  
    my ( $z_12xlGkT,  $pmf_stderr ); 
    my ( $z_12xEpot, $epot_stderr );  

    # parse REPORT 
    read_report    ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot, 1000 ); 

    # block average
    block_average ( \$z_12xlGkT, \$pmf_stderr  );  
    block_average ( \$z_12xEpot, \$epot_stderr );  
    write_stderr  ( \$pmf_stderr, \$epot_stderr => 'block_average.dat' ); 
   
    plot_stderr   ( \$cc, \$pmf_stderr, 'pmf'   );    
    write_stat    ( \$cc, \$z_12, \$z_12xlGkT, \$pmf_stderr  => 'pmf.dat' ),   
    
    plot_stderr   ( \$cc, \$epot_stderr, 'epot' );    
    write_stat    ( \$cc, \$z_12, \$z_12xEpot, \$epot_stderr => 'epot.dat' ),   
    
    chdir $top_dir; 
} 
