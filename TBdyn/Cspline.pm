package Cspline; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use PDL; 
use PDL::GSL::INTERP;
use File::Find; 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( cspline minima maxima ); 

sub cspline ( $energy, $spline ) { 
    my @cc = sort { $a <=> $b } keys $energy->%*; 

    # cubic spline object 
    my $x = PDL->new( @cc );  
    my $y = PDL->new( $energy->@{ @cc } ); 
    my $csp = PDL::GSL::INTERP->init( 'cspline', $x, $y ); 

    # grid
    my $ngrid = 1000; 
    my $dgrid = ( $cc[-1] - $cc[0] ) / $ngrid; 
    my @grids = map { $cc[0] + $_* $dgrid } 0..$ngrid; 

    # interpolation 
    # remove final points ? 
    $spline->%* = map { $grids[$_] => $csp->eval( $grids[$_] ) } 0..$#grids-1; 
} 

sub minima ( $spline ) { 
    my @sorted = sort { $spline->{$a} <=> $spline->{$b} } keys $spline->%*; 
    printf "=> Minima:%7.3f (A)\t%7.3f (eV)\n", $sorted[0], $spline->{ $sorted[0] }
} 

sub maxima ( $spline ) { 
    my @sorted = sort { $spline->{$a} <=> $spline->{$b} } keys $spline->%*; 
    printf "=> Minima:%7.3f (A)\t%7.3f (eV)\n", $sorted[-1], $spline->{ $sorted[-1] }
} 

1
