package Pmf; 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( read_pmf trapezoidal print_free_ene plot_free_ene );  

sub read_pmf ( $pmf ) { 
    for ( IO::KISS->new( 'pmf.dat', 'r' )->get_lines ) { 
        my ( $cc, $mean_grad, $se ) = split; 
        # variance of gradient: stdv**2
        $pmf->{ $cc } = [ $mean_grad, $se**2 ] 
    } 
} 

sub trapezoidal ( $pmf, $trapz ) { 
    my @cc  = sort { $a <=> $b } keys $pmf->%*; 

    #  1st index of trapz is free energy 
    my $sum  = 0; 
    $trapz->{ $cc[0] }[0] = 0;  

    for my $index ( 0..$#cc - 1 ) { 
        my $h = $cc[ $index+1 ] - $cc[ $index ]; 
        $sum += 0.5 * $h * ( $pmf->{ $cc[ $index ] }[0] + $pmf->{ $cc[ $index+1 ] }[0] ); 
        $trapz->{ $cc[$index+1] }[0] = $sum;
    }

    # 2nd index of trapz is variance
    # first two is trivial 
    $trapz->{ $cc[0] }[1] = 0;    
    $trapz->{ $cc[1] }[1] = 
        0.5 * ( $cc[1] - $cc[0] ) * sqrt( $pmf->{ $cc[0] }[1] + $pmf->{ $cc[1] }[1] ); 

    # from #2 to the end 
    for my $i ( 2..$#cc ) { 
        # first and last point 
        my $variance = 
            0.25 * ( $cc[ 1] - $cc[ 0] )**2 * $pmf->{ $cc[ 0] }[1] +  
            0.25 * ( $cc[-1] - $cc[-2] )**2 * $pmf->{ $cc[-1] }[1] ; 

        # this is due to cancellation of trapz form
        for my $j ( 1..$i-1 ) {  
            $variance += 0.25 * ( $cc[$j+1] - $cc[$j-1] )**2 * $pmf->{ $cc[$j] }[1];  
        }

        # stderr
        $trapz->{ $cc[$i] }[1] = sqrt( $variance )
    } 
} 

sub print_free_ene ( $trapz, $output ) { 
    print "=> Free energy with statistical error: $output\n"; 
    
    my $io = IO::KISS->new( $output, 'w' ); 
    
    for ( sort { $a <=> $b } keys $trapz->%* ) { 
        $io->printf( "%f\t%f\t%f\n", $_, $trapz->{ $_ }->@* )
    } 

    $io->close; 
} 

sub plot_free_ene ( $trapz, $spline ) { 
    my $figure = gpwin( 'x11', persist => 1, raise => 1 ); 

    my @cc    = sort { $a <=> $b } keys $trapz->%*;  
    my @grids = sort { $a <=> $b } keys $spline->%*;  

    my $x1  = PDL->new( @cc );  
    my $y1  = PDL->new( map $trapz->{$_}[0], @cc ); 
    my $y1e = PDL->new( map $trapz->{$_}[1], @cc ); 

    my $x2 = PDL->new( @grids ); 
    my $y2 = PDL->new( $spline->@{ @grids } ); 

    # zero 
    my $zero = zeroes( scalar( @cc ) );

    # yrange 
    # min and max clash with PDL
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
            with      => 'yerrorbars',
            tuplesize => 3,
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 2,
            # pointsize => 2,
            # pointtype => 4,
            legend    => 'Integrated <dA/ds>' 
        ), $x1, $y1, $y1e, 

        ( 
            with      => 'lines', 
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 1, 
            legend    => 'Cubic splines' 
        ), $x2, $y2, 

        ( 
            with      => 'lines', 
            linestyle => -1,
            linewidth =>  1, 
        ), $x1, $zero  
    )
}


1
