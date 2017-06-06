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
    my ( $cc, $z_12, $lpGkT, $e_pot ); 

    # block statistic  
    my ( $bsize, $bavg, $bstdv, $bstde ); 

    # parse REPORT 
    read_report  ( \$cc, \$z_12, \$lpGkT, \$e_pot ); 

    # gradient 
    block_average( \$z_12,  \$lpGkT, \$bsize, \$bavg, \$bstdv, \$bstde ); 
    plot_stderr  ( \$cc, \$bsize, \$bstde, 'gradient', 'red' ); 
    write_stderr ( \$cc, \$bsize, \$bavg, \$bstdv, \$bstde => 'blocked_grad.dat' );  

    # potential 
    block_average( \$z_12, \$e_pot, \$bsize, \$bavg, \$bstdv, \$bstde ); 
    plot_stderr  ( \$cc, \$bsize, \$bstde, 'potential', 'blue' ); 
    write_stderr ( \$cc, \$bsize, \$bavg, \$bstdv, \$bstde => 'blocked_pot.dat' );  

    # return 
    chdir $top_dir; 
} 
