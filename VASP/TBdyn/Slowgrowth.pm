package VASP::TBdyn::Slowgrowth; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use VASP::TBdyn::Color; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    integ_slow_growth 
    write_slow_growth
    plot_slow_growth
); 

sub integ_slow_growth ( $cc, $gradient, $free_ene) { 
    # not the most elegant, but ... 
    ( $$cc, $$gradient ) = cat( $$cc, $$gradient )->xchg(0,1)->qsortvec->xchg(0,1)->dog; 

    my $cspline = PDL::GSL::INTERP->init( 'cspline', $$cc, $$gradient ); 

    # initialize to zero
    $$free_ene = PDL->zeroes( $$cc->nelem ); 

    # slice asignment
    $$free_ene->slice( "1:") .= PDL->new( 
        map $cspline->integ( $$cc->at(0), $$cc->at($_) ), 
        1 .. $$cc->nelem - 1 
    ); 
} 

sub write_slow_growth ( $cc, $gradient, $free_ene, $output ) { 
    my $fh = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$cc->nelem - 1 ) { 
        $fh->printf( 
            "%10.5f  %10.5f  %10.5f\n", 
                  $$cc->at( $_ ), 
            $$gradient->at( $_ ), 
            $$free_ene->at( $_ )
        )
    }

    $fh->close; 
} 

sub plot_slow_growth ( $cc, $gradient, $free_ene ) { 
    my $zeroes = PDL->zeroes( $$cc->nelem );  

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1, 
        font     => 'Helvetica,14',
    ); 
   
    $figure->plot( 
        # plot options
        { 
            title  => 'Slow Growth',  
            xrange => sprintf( "%.1f:%.1f", $$cc->min, $$cc->max ), 
            xlabel => 'Reaction Coordinate', 
            ylabel => '{/Symbol \266}A / {/Symbol \266}{/Symbol x}', 
            key    => 'top right spacing 1.5', 
            size   => 'ratio 0.75',
            grid   => 1, 
        }, 

        # gradient
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 2, 
            linecolor => [ rgb => $hcolor{ red } ], 
            legend    => 'Gradient', 
        ), $$cc, $$gradient, 
        
        # free energy
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 3, 
            linecolor => [ rgb => $hcolor{ white } ], 
            legend    => 'Free Energy', 
        ), $$cc, $$free_ene, 

        # zero 
        ( 
            with      => 'lines', 
            linestyle => -1, 
            linecolor => [ rgb => $hcolor{ white } ], 
        ), $$cc, $zeroes
    )
}

1
