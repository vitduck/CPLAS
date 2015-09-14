#!/usr/bin/env perl 

use strict; 
use warnings; 

use List::Util qw( sum max min ); 

my $index = 2; 

my ($geom, $title, $scaling, @lat, $atom, $natom, $mode, @coor); 
my ($locpot, @grid, @locpot, @llocpot);  
my ($avg_grid, @avg_pot, $format); 

# fortran blank line does no work with perl paragraph mode ?
($geom, $locpot) = split /\n+\s*\n+/, do { local $/; <> }; 

# parse geometry block
($title, $scaling, @lat[0..2], $atom, $natom, $mode, @coor) = split /\n/, $geom; 

# parse locpot block
(@grid[0..2], @locpot) = split ' ', $locpot; 

# Fortran is column-wise order
# There is no other way around this without relying on the Schwartzian shenanigans
# which will cause overhead during sorting and transformation :(
# Algorith::Loops by Tye McQueen is potential faster ?
for my $iz (0..$grid[2]-1) { 
    for my $iy (0..$grid[1]-1) { 
        for my $ix (0..$grid[0]-1) { 
            ( push @{$llocpot[$iz][$iy]}, shift @locpot ) && ( next ) if $index == 0;  
            ( push @{$llocpot[$iz][$ix]}, shift @locpot ) && ( next ) if $index == 1;  
            ( push @{$llocpot[$iy][$ix]}, shift @locpot ) && ( next ) if $index == 2;  
        }
    }
}

# avg line
$avg_grid = $grid[$index]; 

# set the grid to 1 for the new LOCPOT 
$grid[$index] = 1;

# average along the $index direction
@avg_pot = map { map { sum(@$_)/$avg_grid } @$_ } @llocpot; 

# color scale
printf "Max value of LOCPOT: %f\n", max(@avg_pot); 
printf "Min value of LOCPOT: %f\n", min(@avg_pot); 

# locpot format 
$format = join '', map { (($_+1) % 5) ? "%17.10E\t" : "%17.10E\n" } 0 .. $#avg_pot; 

# write output
open OUTPUT, '>', 'avg_LOCPOT.vasp'; 
printf OUTPUT "%s\n\n", $geom; 
printf OUTPUT "%d\t%d\t%d\n", @grid; 
printf OUTPUT $format, @avg_pot; 
close OUTPUT; 
