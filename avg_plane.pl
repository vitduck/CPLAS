#!/usr/bin/env perl 

use strict; 
use warnings; 
use List::Util qw(sum max min); 

my $index = 2; 
my $periodic_lat = 4.75; 

my ($geom, $title, $scaling, @lat, $atom, $natom, $mode, @coor); 
my ($locpot, @grid, @locpot, @plocpot);  

# fortran blank line does not work with perl paragraph mode ?
# actually it works, but the blank lines of LOCPOT is not correctly regconized 
($geom, $locpot) = split /\n+\s*\n+/, do { local $/; <> }; 

# parse geometry block
($title, $scaling, @lat[0..2], $atom, $natom, $mode, @coor) = split /\n/, $geom; 

# parse locpot block
(@grid[0..2], @locpot) = split ' ', $locpot; 

# Fortran is column-wise order
# There is no other way around this without relying on the Schwartzian shenanigans
# which will cause huge overhead during sorting :(
# Algorith::Loops by Tye McQueen is potentially faster ?
for my $iz (0..$grid[2]-1) { 
    for my $iy (0..$grid[1]-1) { 
        for my $ix (0..$grid[0]-1) { 
            ( push @{$plocpot[$ix]}, shift @locpot ) && ( next ) if $index == 0;  
            ( push @{$plocpot[$iy]}, shift @locpot ) && ( next ) if $index == 1;  
            ( push @{$plocpot[$iz]}, shift @locpot ) && ( next ) if $index == 2;  
        }
    }
}

# avg plane 
my $avg_grid = splice @grid, $index, 1; 
my $avg_plane = $grid[0]*$grid[1]; 

# x axis
my ($vx, $vy, $vz) = split ' ', $lat[$index]; 
my $dx = sqrt( $vx*$vx + $vy*$vy + $vz*$vz )/$avg_grid;  
my @x = map { $dx*$_ } 0..$avg_grid;  

# microscopic average
my @micro_avg = map { sum(@$_)/$avg_plane } @plocpot;  

# macroscopic average 
my @macro_avg;
my $periodic_grid = int($periodic_lat/$dx); 

for my $i (0..$#micro_avg) { 
    for my $j (($i-int($periodic_grid/2))..($i+int($periodic_grid/2)-1)) { 
        if ( $j < 0 ) { 
            $macro_avg[$i] += $micro_avg[$j + $avg_grid]; 
        } elsif ( $j >= $avg_grid ) { 
            $macro_avg[$i] += $micro_avg[$j - $avg_grid]; 
        } else { 
            $macro_avg[$i] += $micro_avg[$j]; 
        }
    }
    $macro_avg[$i] /= $periodic_grid; 
}

printf "Macroscopic average: %-15.8e\n", sum(@macro_avg)/$periodic_grid; 

# join the first and last point of the potential
push @micro_avg, $micro_avg[0]; 
push @macro_avg, $macro_avg[0]; 

# write output
open OUTPUT, '>', 'avg.dat'; 
printf OUTPUT "# %-8s\t%-8s\t%-8s\n", qw(Distance Microscopic Macroscopic); 
map { printf OUTPUT "%-15.8f\t%-15.8f\t%-15.8f\n", $x[$_], $micro_avg[$_], $macro_avg[$_] } 0..$avg_grid; 
close OUTPUT; 
