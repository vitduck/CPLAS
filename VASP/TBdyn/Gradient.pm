package VASP::TBdyn::Gradient; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Stats::TS; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use VASP::TBdyn::Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    get_gradient
    plot_gradient
); 

sub get_gradient ( $z_12, $z_12xlGkT, $gradient, $avg_gradient, $output ) { 
    # instantaneous gradient 
    $$gradient = $$z_12xlGkT / $$z_12; 

    # moving average filter 
    $$avg_gradient = $$z_12xlGkT->dseason(250) / $$z_12->dseason(250);   

    # write gradients to file
    my $fh = IO::KISS->new( $output, 'w' ); 

    for ( 0..$->nelem - 1 ) { 
        $fh->printf( 
            "%d %15.8f %15.8f\n", 
            $_+1,
            $$gradient->at($_), 
            $$avg_gradient->at($_)
        )
    }

    $fh->close; 
} 

sub plot_gradient ( $cc, $gradient, $avg_gradient ) { 
    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1,
        font     => 'terminal-14',
    ); 

    $figure->plot( 
        # plot options
        { 
            title  => sprintf( "{/Symbol x} = %.3f", $$cc->at(0) ),  
            xlabel => 'MD Step', 
            ylabel => 'Gradient', 
            xrange => '[100:]',
            grid   => 1
        }, 

        # igradient.dat
        ( 
            with      => 'lines', 
            linewidth => 2, 
            linecolor => [ rgb => $hcolor{ red } ], 
            legend    => '{/Symbol \266}A/{/Symbol \266}{/Symbol x}', 
        ), PDL->new( 1.. $$cc->nelem ), $$gradient, 
        
        # mgradient.dat
        ( 
            with      => 'lines', 
            linestyle => -1, 
            linewidth => 2, 
            legend    => '<{/Symbol \266}A/{/Symbol \266}{/Symbol x}>', 
        ), PDL->new( 1.. $$cc->nelem ), $$avg_gradient, 
    )
}
