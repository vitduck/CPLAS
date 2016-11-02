package Plot; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use PDL; 
use PDL::Graphics::Gnuplot; 
use File::Find; 
use List::Util qw(); 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( plot_free_ene plot_grad ); 

our %color = ( 
    red  => "#cc9393", 
    blue => "#94bff3",  
); 

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

sub plot_grad ( $gradient, $average ) { 
    my $figure = gpwin( 'x11', persist => 1, raise => 1 ); 
    
    my @steps = 0..$gradient->$#*;  
    my $x  = PDL->new( @steps );  
    my $y1 = PDL->new( $gradient->@* );  
    my $y2 = PDL->new( $average->@* ); 

    $figure->plot( 
        # plot options
        { 
            xlabel => 'NSTEP', 
            ylabel => 'eV',
            grid   => 1
        }, 

        # curve options 
        ( 
            with      => 'lines', 
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 2, 
            legend    => 'dA/ds'
        ), $x, $y1, 
        
        ( 
            with      => 'lines', 
            linecolor => [ rgb => $color{ blue } ], 
            linewidth => 2, 
            legend    => '<dA/ds>' 
        ), $x, $y2, 
    )
}

1
