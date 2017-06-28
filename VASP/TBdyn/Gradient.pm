package VASP::TBdyn::Gradient; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Stats::TS; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use VASP::TBdyn::Color; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    get_gradient
    get_avg_gradient
    write_avg_gradient
    plot_avg_gradient
); 

sub get_gradient ( $z_12, $z_12xlGkT, $gradient ) {  
    $$gradient = $$z_12xlGkT / $$z_12; 
}

sub get_avg_gradient ( $z_12, $z_12xlGkT, $avg_gradient, $period = 250 ) { 
    $$avg_gradient = $$z_12xlGkT->filter_ma( $period ) / $$z_12->filter_ma( $period );   
}

sub write_avg_gradient ( $gradient, $avg_gradient, $output ) {  
    my $fh = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$gradient->nelem - 1 ) { 
        $fh->printf( 
            "%d %15.8f %15.8f\n", 
            $_+1,
            $$gradient->at($_), 
            $$avg_gradient->at($_)
        )
    }

    $fh->close; 
} 

sub plot_avg_gradient ( $cc, $gradient, $avg_gradient ) { 
    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1,
    ); 

    $figure->plot( 
        # plot options
        { 
            title  => sprintf( "Constrain {/Symbol x} = %.3f", $$cc->at(0) ),  
            xlabel => 'MD step', 
            ylabel => '{/Symbol \266}A / {/Symbol \266}{/Symbol x}', 
            key    => 'top right spacing 1.5',
            size   => 'ratio 0.666', 
            # grid   => 1, 
        }, 

        # gradient
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 2, 
            linecolor => [ rgb => $hcolor{ red } ], 
            legend    => 'Gradient', 
        ), PDL->new( 1.. $$cc->nelem ), $$gradient, 
        
        # avg_gradient
        ( 
            with      => 'lines', 
            dashtype  => 1,  
            linewidth => 3, 
            linecolor => [ rgb => $hcolor{ white } ], 
            legend    => 'Moving average', 
        ), PDL->new( 1.. $$cc->nelem ), $$avg_gradient, 
    )
}
