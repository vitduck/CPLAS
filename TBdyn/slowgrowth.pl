#!/usr/bin/env perl 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::GSL::INTERP; 
use PDL::Graphics::Gnuplot; 

use IO::KISS; 
use Data::Printer; 

my ( $cc, $gradient, $trapz );  

read_slowgrowth( \$cc, \$gradient ); 
int_slowgrowth ( \$cc, \$gradient, \$trapz => 'trapz.dat' );  
plot_slowgrowth( \$cc, \$gradient, \$trapz ); 

sub read_slowgrowth ( $cc, $gradient ) {  
    my ( @cc, @gradient ); 

    for ( IO::KISS->new( 'REPORT', 'r' )->get_lines ) { 
        if ( /cc/ ) { 
            push @cc, ( split )[2]
        }

        if ( /b_m>/ ) {  
            my ( $z, $GkT ) =  ( split )[2,-1]; 
            push @gradient, $GkT / $z; 
        } 
    } 

    # PDL 
    $$cc       = PDL->new( @cc ); 
    $$gradient = PDL->new( @gradient ); 
} 

sub int_slowgrowth ( $cc, $gradient, $trapz, $output ) {  

    my $spl = PDL::GSL::INTERP->init( 'cspline', $$cc, $$gradient ); 
    my $io  = IO::KISS->new( $output, 'w' ); 
    
    my @trapz; 
    for ( 0 .. $$cc->nelem-1 ) { 
        my $dA += $spl->integ( $$cc->index(0), $$cc->index($_) );  

        push @trapz, $dA; 
        
        $io->printf( 
            "%7.3f\t%7.3f\t%7.3f\n", 
            $$cc->index($_),  
            $$gradient->index($_), 
            $dA 
        )

    } 
    $io->close; 

    #PDL 
    $$trapz = PDL->new( @trapz )
}

sub plot_slowgrowth ( $cc, $gradient, $trapz ) { 
    my $figure = gpwin( 
        'x11', 
        persist => 1, 
        raise   => 1 
    ); 

    # piddle 
    my $zero = zeroes( $$cc->nelem ); 

    # range 
    # my $min_x = min( $x );  
    # my $max_x = max( $x ); 

    $figure->plot( 
        # plot options
        { 
            # xrange => [ $min_x, $max_x ], 
            xlabel => 'Reaction Coordinate', 
            # ylabel => 'kcal/mol', 
            # ylabel => 'kj/mol',
            # ytics  => 0.5, 
            grid   => 1
        }, 

        # curve options 
        ( 
            with      => 'lines', 
            linecolor => [ rgb => "#cc9393" ], 
            linewidth => 1, 
            legend    => 'Gradient'
        ), $$cc, $$gradient, 
        
        ( 
            with      => 'lines', 
            linecolor => [ rgb => "#94bff3" ], 
            linewidth => 3, 
            legend    => 'Free energy' 
        ), $$cc, $$trapz, 

        ( 
            with      => 'lines', 
            linestyle => -1,
        ), $$cc, $zero,  
    )
}
