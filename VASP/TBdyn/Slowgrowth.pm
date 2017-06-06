package VASP::TBdyn::Slowgrowth; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use VASP::TBdyn::Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    integ_slow_growth 
    write_slow_growth
    plot_slow_growth
); 

sub integ_slow_growth ( $cc, $gradient, $free_ene) { 
    my $cspline = PDL::GSL::INTERP->init( 'cspline', $$cc, $$gradient ); 

    # initialize to zero
    $$free_ene = PDL->zeroes( $$cc->nelem ); 

    # slice asignment
    $$free_ene->slice( "1:") .=  
        PDL->new( 
            map $cspline->integ( $$cc->at(0), $$cc->at($_) ), 
            1 .. $$cc->nelem - 1 
        ); 
} 

sub write_slow_growth ( $cc, $gradient, $free_ene, $output ) { 
    my $io  = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$cc->nelem - 1 ) { 
        $io->printf( 
            "%10.5f  %10.5f  %10.5f\n", 
                  $$cc->at( $_ ), 
            $$gradient->at( $_ ), 
            $$free_ene->at( $_ )
        )
    }

    $io->close; 
} 

sub plot_slow_growth ( $cc, $gradient, $free_ene ) { 
    my $zeroes = PDL->zeroes( $$cc->nelem );  

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 
   
    $figure->plot( 
        # plot options
        { 
            title  => 'Slow growth integration',  
            xlabel => 'Reaction Coordinate (A)', 
            ylabel => 'Free Energy (eV)',
            key    => 'spacing 1.5', 
            grid   => 1, 
        }, 

        # gradient
        ( 
            with      => 'lines', 
            linecolor => [ rgb => $hcolor{ red } ], 
            linewidth => 3, 
            legend    => '{/Symbol \266}A/{/Symbol \266}{/Symbol x}', 
        ), $$cc, $$gradient, 
        
        # free energy
        ( 
            with      => 'lines', 
            linestyle => -1, 
            linewidth => 3, 
            legend    => '{/Symbol D}A'
        ), $$cc, $$free_ene, 

        # xaxis 
        ( 
            with      => 'lines', 
            linestyle => -1, 
        ), $$cc, $zeroes
    )
}

1
