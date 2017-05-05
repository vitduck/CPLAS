package Pmf; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 
use Data::Printer; 

use Plot; 
use IO::KISS;  

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_pmf 
    integ_trapz
    print_free_ene 
    plot_free_ene 
);  

sub read_pmf ( $input, $cc, $gradient, $variance ) { 
    my ( @cc, @gradients, @variances ); 

    for ( IO::KISS->new( $input, 'r' )->get_lines ) { 
        next if /#/; 

        my ( $cc, $gradient, $stdv, $se ) = split; 

        push @cc, $cc; 
        push @gradients, $gradient; 
        push @variances, $stdv**2; 
    } 

    # deref PDL piddle
    $$cc       = PDL->new( @cc ); 
    $$gradient = PDL->new( @gradients ); 
    $$variance = PDL->new( @variances ); 
} 

sub integ_trapz ( $cc, $gradient, $variance, $free_ene, $prop_err ) { 
    my ( @free_enes, @prop_errs ); 

    # reference point 
    $free_enes[0] = 0; 
    $prop_errs[0] = 0; 

    # Trapezoidal integration
    # Ref: T. Bucko, Journal of Cataylysis (2007)
    for my $i ( 1 .. $$cc->nelem - 1 ) { 
        # first and last point
        $free_enes[$i] = 
            0.50 * $$gradient->at(0)  * ( $$cc->at(1)  - $$cc->at(0) ) + 
            0.50 * $$gradient->at($i) * ( $$cc->at($i) - $$cc->at($i-1) ); 

        $prop_errs[$i] = 
            0.25 * $$variance->at(0)  * ( $$cc->at(1)  - $$cc->at(0) )**2 + 
            0.25 * $$variance->at($i) * ( $$cc->at($i)  - $$cc->at($i-1) )**2; 
            
        # middle point with cancellation
        for my $j ( 1..$i - 1 ) { 
            $free_enes[$i] += 
                0.50 * $$gradient->at($j) * ( $$cc->at($j+1) - $$cc->at($j-1) ); 
            
            $prop_errs[$i] += 
                0.25 * $$variance->at($j) * ( $$cc->at($j+1) - $$cc->at($j-1) )**2 
        } 

    }

    # deref PDL piddle 
    $$free_ene = PDL->new( @free_enes );  
    $$prop_err = PDL->new( @prop_errs )->sqrt;  
}

sub print_free_ene ( $cc, $free_ene, $prop_err, $output ) { 
    my $io = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$cc->nelem - 1 ) { 
        $io->printf( 
            "%10.5f  %10.5f  %10.5f\n", 
                  $$cc->at( $_ ), 
            $$free_ene->at( $_ ), 
            $$prop_err->at( $_ )
        )
    }
    
    $io->close; 
} 

sub plot_free_ene ( $cc, $free_ene, $prop_err ) { 
    my $zeroes = PDL->zeroes( $$cc->nelem );  

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 

    my ( $x_min, $x_max ) = ( $$cc->min, $$cc->max ); 
    my ( $y_min, $y_max ) = ( $$free_ene->min, $$free_ene->max ); 

    $figure->plot( 
        # plot options
        { 
            xlabel => 'Reaction Coordinate (A)', 
            ylabel => 'Free Energy (eV)',
            xrange => [ $x_min - 0.05, $x_max + 0.05 ], 
            yrange => [ $y_min - 0.50, $y_max + 0.50 ], 
            grid   => 1,
        }, 

        # cubic spline
        ( 
            with      => 'lines', 
            linecolor => [ rgb => $color{ red } ], 
            linewidth => 3, 
            smooth    => 'cspline', 
        ), $$cc, $$free_ene, 

        # free energy 
        ( 
            with      => 'yerrorbars',
            tuplesize => 3,
            linestyle => -1, 
            linewidth => 2,
            pointsize => 1,
            pointtype => 4,
            legend    => '{/Symbol D}A', 
        ), $$cc, $$free_ene, $$prop_err, 

        ( 
            with      => 'lines', 
            linestyle => -1,
            linewidth =>  2, 
        ), $$cc, $zeroes  
    )
}

1
