package VASP::TBdyn::Internal; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Graphics::Gnuplot; 
use VASP::TBdyn::Color; 

our @ISA    = qw( Exporter   ); 
our @EXPORT = qw( pl_epot_avg pl_epot_err internal );  

# dU wrt to reference point
sub internal  ( $epot ) { 
    $$epot = $$epot - $$epot->at(0); 
}

sub pl_epot_avg ( $cc, $internal ) { 
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
            title  => sprintf( "Internal Energy ({/Symbol x} = %.3f)", $$cc->at(0) ),  
            xlabel => 'MD step', 
            ylabel => 'Energy', 
            xrange => '[250:]'
        }, 

        # gradient
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 4, 
            linecolor => [ rgb => $hcolor{ blue } ], 
        ), PDL->new( 1.. $$cc->nelem ), $$internal 
    )
}

sub pl_epot_err ( $cc, $int_error ) { 
    # x-axis: block size
    my $bsize = PDL->new( 1..$$int_error->nelem ); 

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
            title  => sprintf( "|z|^{-1/2} * E_pot ({/Symbol x} = %.3f)", $$cc->at(0) ),  
            xlabel => 'N_b',
            ylabel => 'Standard Error', 
            size   => 'ratio 0.75', 
            grid   => 1
        }, 
        
        ( 
            with      => 'point', 
            linewidth => 2,
            pointtype => 4, 
            linecolor => [ rgb => $hcolor{ 'blue' } ], 
        ), $bsize, $$int_error 
    )
} 

1
