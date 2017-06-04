package Gradient; 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Stats::Basic; 
use PDL::Graphics::Gnuplot; 

use IO::KISS;  
use Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_report 
    get_gradient
    get_avg_gradient
    write_gradient
    write_avg_gradient
    plot_gradient
); 

sub read_report ( $cc, $z_12, $lpGkT, $nequilibrium = 0 ) { 
    my ( @cc, @z_12, @lpGkT );  

    my $report = IO::KISS->new( 'REPORT', 'r' ); 

    while ( local $_ = $report->get_line ) { 
        # constraint 
        if ( /cc>/  ) { 
            push @cc, ( split )[2] 
        } 

        # blue moon
        if ( /b_m>/ ) {  
            my @bm = split; 
            push @z_12,  $bm[ 2]; 
            push @lpGkT, $bm[-1]; 
        }
    } 

    $report->close; 

    # equilibrartion 
    map { splice @$_, 0, $nequilibrium } ( \@cc, \@z_12, \@lpGkT ); 

    # deref the piddle
    $$cc    = PDL->new( @cc    ); 
    $$z_12  = PDL->new( @z_12  ); 
    $$lpGkT = PDL->new( @lpGkT ); 
}

sub get_gradient ( $z_12, $lpGkT, $gradient ) { 
    $$gradient = $$lpGkT / $$z_12; 
} 

sub get_avg_gradient ( $cc, $z_12, $lpGkT, $moving_index, $moving_gradient ) { 
    # default !
    my $size  = 25; 
    my $bound = -1; 
    my $nelem = $$z_12->nelem; 

    my ( @moving_index, @moving_gradient ); 

    while ( 1 ) { 
        $bound += $size; 

        last if $bound > $nelem; 

        push @moving_index, $bound;  
        push @moving_gradient, 
            $$lpGkT->slice( "0:$bound" )->sum / $$z_12->slice( "0:$bound" )->sum;
    } 
    
    $$moving_index    = PDL->new( @moving_index ); 
    $$moving_gradient = PDL->new( @moving_gradient ); 
}

sub write_gradient ( $gradient, $output ) {
    my $io = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$gradient->nelem - 1 ) { 
        $io->printf( "%d  %10.5f\n", $_, $$gradient->at( $_ ) )
    }

    $io->close; 
}

sub write_avg_gradient ( $moving_index, $moving_gradient, $output ) {
    my $io = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$moving_index->nelem - 1 ) { 
        $io->printf( 
            "%d  %10.5f\n", 
            $$moving_index->at( $_ ), 
            $$moving_gradient->at( $_ ), 
        )
    }
    
    $io->close; 
}

sub plot_gradient ( $cc, $gradient, $moving_index, $moving_gradient ) { 
    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 

    $figure->plot( 
        # plot options
        { 
            title  => sprintf( "d = %-7.3f", $$cc->at(0) ),  
            xlabel => 'MD Step', 
            ylabel => 'Gradient (eV/A)', 
            xrange => '[100:]',
            grid   => 1
        }, 

        # igradient.dat
        ( 
            with      => 'lines', 
            linewidth => 2, 
            linecolor => [ rgb => $color{ red } ], 
            legend    => '{/Symbol \266}A/{/Symbol \266}{/Symbol x}', 
        ), PDL->new( 1.. $$cc->nelem ), $$gradient, 
        
        # mgradient.dat
        ( 
            with      => 'lines', 
            linestyle => -1, 
            linewidth => 2, 
            legend    => '<{/Symbol \266}A/{/Symbol \266}{/Symbol x}>', 
        ), $$moving_index, $$moving_gradient
    )
}
