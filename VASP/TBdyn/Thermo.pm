package VASP::TBdyn::Thermo; 

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
    read_data
    print_thermo
    plot_thermo
); 

sub read_data ( $input, $cc, $thermo, $variance ) { 
    my ( @cc, @thermos, @variances ); 

    for ( IO::KISS->new( $input, 'r' )->get_lines ) { 
        next if /#/; 

        my ( $cc, undef, $thermo, $se ) = split; 

        push @cc, $cc; 
        push @thermos, $thermo; 
        push @variances, $se**2; 
    } 

    # deref PDL piddle
    $$cc       = PDL->new( @cc ); 
    $$thermo   = PDL->new( @thermos ); 
    $$variance = PDL->new( @variances ); 
} 

sub print_thermo ( $cc, $thermo, $variance, $output ) { 
    my $io = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$cc->nelem - 1 ) { 
        $io->printf( 
            "%7.3f  %10.5f  %10.5f\n", 
            $$cc->at( $_ ), 
            $$thermo->at( $_ ), 
            sqrt( $$variance->at( $_ ) )
        )
    }
    
    $io->close; 
    
    print "=> $output\n"; 
} 

sub plot_thermo ( $cc, $thermo, $variance, $type ) { 
    my %plot = ( 
        'dA' => { 
            title => '{/Symbol D}A', 
            color => 'red', 
            pt    => 4,
        }, 
        'dU' => { 
            title => '{/Symbol D}U', 
            color => 'blue', 
            pt    => 6,
        }, 
        'TdS' => { 
            title => 'T{/Symbol D}S = {/Symbol D}A - {/Symbol D}U', 
            color => 'green', 
            pt    => 8,
        }
    ); 

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 

    $figure->plot( 
        # plot options
        { 
            title  => $plot{ $type }{ title }, 
            xlabel => 'Reaction Coordinate (A)', 
            ylabel => 'Energy (eV)',
            xrange => [ $$cc->min-0.05, $$cc->max+0.05 ], 
            size   => 'ratio 0.75', 
            grid   => 1, 
        }, 

        # thermo data
        ( 
            with      => 'lines', 
            linecolor => $hcolor{ $plot{ $type }{ color } }, 
            dashtype  => 1, 
            linewidth => 3, 
        ), $$cc, $$thermo, 

        # error bar
        ( 
            with      => 'yerrorbars',
            tuplesize => 3,
            linewidth => 2,
            pointtype => $plot{ $type }{ pt }, 
            linecolor => $hcolor{ white }, 
        ), $$cc, $$thermo, $$variance->sqrt, 
    )
}

1; 
