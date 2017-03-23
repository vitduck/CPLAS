package Pmf; 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( read_pmf trapezoidal plot_free_ene );  

sub read_pmf ( $pmf ) { 
    for ( IO::KISS->new( 'pmf.dat', 'r' )->get_lines ) { 
        my ( $cc, $mean_grad ) = split; 
        $pmf->{ $cc } = $mean_grad; 
    } 
} 

sub trapezoidal ( $pmf, $trapz ) { 
    my @cc  = sort { $a <=> $b } keys $pmf->%*; 
        
    # reference 
    $trapz->{ $cc[0] } = 0; 

    # pair-wise summatin
    my $sum = 0; 
    for my $index ( 0..$#cc - 1 ) { 
        my $h = $cc[ $index+1 ] - $cc[ $index ]; 
        $sum += 0.5 * $h * ( $pmf->{ $cc[ $index ] } + $pmf->{ $cc[ $index+1 ] } ); 
        $trapz->{ $cc[$index+1] } = $sum; 
    } 
} 

sub plot_free_ene ( $energy, $spline ) { 
    my $figure = gpwin( 'x11', persist => 1, raise => 1 ); 

    my @cc    = sort { $a <=> $b } keys $energy->%*;  
    my @grids = sort { $a <=> $b } keys $spline->%*;  

    my $x1 = PDL->new( @cc );  
    my $y1 = PDL->new( $energy->@{ @cc } ); 

    my $x2 = PDL->new( @grids ); 
    my $y2 = PDL->new( $spline->@{ @grids } ); 

    # zero 
    my $zero = zeroes( scalar( @cc ) );

    # yrange 
    my $y_min = List::Util::min( $spline->@{ @grids } ); 
    my $y_max = List::Util::max( $spline->@{ @grids } ); 


    $figure->plot( 
        # plot options
        { 
            xlabel => 'Reaction Path (A)', 
            xtics  => 0.25,  

            ylabel => 'Free Energy (eV)',
            # ytics  => 0.25, 
            yrange => [ $y_min - 0.25, $y_max + 0.25 ], 

            grid   => 1,
        }, 

        ( 
            with      => 'points',
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 3,
            pointsize => 2,
            pointtype => 4,
            legend    => 'Integrated <dA/ds>' 
        ), $x1, $y1, 

        ( 
            with      => 'lines', 
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 3, 
            legend    => 'Cubic splines' 
        ), $x2, $y2, 

        ( 
            with      => 'lines', 
            linestyle => -1,
            linewidth =>  2, 
        ), $x1, $zero,  
    )
}


1
