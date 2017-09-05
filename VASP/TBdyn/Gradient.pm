package VASP::TBdyn::Gradient; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 
use VASP::TBdyn::Color; 

our @ISA    = qw( Exporter );  
our @EXPORT = qw( pl_grad_avg pl_grad_err ); 

sub pl_grad_avg ( $cc, $gradient ) { 
    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1,
    ); 

    $figure->plot( 
        # plot options
        { 
            grid   => 1, 
            size   => 'ratio 0.75', 
            key    => 'top right', 
            title  => sprintf( "Free Energy Gradient ({/Symbol x} = %.3f)", $$cc->at(0) ),  
            xlabel => 'MD step', 
            ylabel => '{/Symbol \266}A / {/Symbol \266}{/Symbol x}', 
            xrange => '[250:]', 
        }, 

        # gradient
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 4, 
            linecolor => [ rgb => $hcolor{ red } ], 
        ), PDL->new( 1.. $$cc->nelem ), $$gradient, 
    )
}

sub pl_grad_err ( $cc, $grad_error ) { 
    # x-axis: block size
    my $bsize = PDL->new( 1..$$grad_error->nelem ); 

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1, 
    ); 

    $figure->plot( 
        # plot options
        { 
            key    => 'top left spacing 2',
            title  => sprintf( "|z|^{-1/2} * ({/Symbol l} + GkT)' ({/Symbol x} = %.3f)", $$cc->at(0) ),  
            xlabel => 'N_b',
            ylabel => 'standard error', 
            size   => 'ratio 0.75', 
            grid   => 1
        }, 

        ( 
            with      => 'point', 
            linewidth => 2,
            pointtype => 6, 
            linecolor => [ rgb => $hcolor{ 'red' } ], 
        ), $bsize, $$grad_error
    )
} 

1
