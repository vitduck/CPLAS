#!/usr/bin/env perl 

use autodie; 
use strict; 
use warnings; 

use Data::Printer; 

use IO::KISS; 
use VASP::TBdyn::Report; 
use VASP::TBdyn::Gradient; 
use VASP::TBdyn::Internal; 
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
    my ( $z_12xlGkT, $grad_err ); 
    my ( $z_12xEpot, $epot_err );  

    read_report ( \$cc, \$z_12, \$z_12xlGkT, \$z_12xEpot, 0 ); 
   
    # gradient 
    block_err   ( \$z_12xlGkT, \$grad_err => 'grad_err.dat' );  
    pl_grad_err ( \$cc, \$grad_err ); 
    ensemble    ( \$cc, \$z_12, \$z_12xlGkT, \$grad_err => 'grad.dat' ); 

    # potential 
    block_err   ( \$z_12xEpot, \$epot_err => 'epot_err.dat' );   
    pl_epot_err ( \$cc, \$epot_err ); 
    ensemble    ( \$cc, \$z_12, \$z_12xEpot, \$epot_err => 'epot.dat' ); 
    
    chdir $top_dir; 
} 
