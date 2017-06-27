package VASP::TBdyn::Statistics; 

use autodie; 
use strict; 
use warnings; 
use experimental qw( signatures ); 

use PDL; 
use PDL::Stats::Basic; 
use PDL::Graphics::Gnuplot; 

use VASP::TBdyn::Plot; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    block_analysis
    write_SI
    plot_SI
); 

sub block_analysis ( $tserie, $bsize, $bvar, $SI ) { 
    my $nelem = $$tserie->nelem; 
    
    my $min_block_size = 2; 
    my $max_block_size = int( $nelem / 20 ); 
    
    my ( @block_sizes, @block_vars ); 
    
    for my $size ( $min_block_size .. $max_block_size ) { 
        my $lb = 0; 
        my $rb = 0; 

        # truncates if neccessary
        my $nblock = int( $nelem / $size ); 

        # average of sub-blocks 
        my @block_avgs;  

        for ( 1 .. $nblock ) { 
            $rb = $lb + $size - 1; 

            push @block_avgs, $$tserie->slice( "$lb:$rb" )->average; 

            # shift left bound
            $lb += $size; 
        } 

        my $block_avg = PDL->new( @block_avgs ); 

        push @block_sizes, $size; 
        push @block_vars, $block_avg->var; 
    }

    $$bsize = PDL->new( @block_sizes ); 
    $$bvar  = PDL->new( @block_vars  ); 

    $$SI = $$bsize * $$bvar / $$tserie->var; 
}

sub write_SI ( $bsize, $SI, $output ) { 
    print "=> blocking analysis for $output\n";

    my $io = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$bsize->nelem -1 ) { 
        $io->printf( "%10.5f %10.5f\n", sqrt( $$bsize->at( $_ ) ), $$SI->at( $_ ) ) 
    }

    $io->close; 
    
} 

sub plot_SI ( $cc, $bsize, $bvar, $SI, $title = 'SI', $color='red' ) { 
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
            title  => sprintf( '%s  (%.3f)', $title, $$cc->at(0) ),  
            xlabel => '{/Symbol=\326}n_b',
            ylabel => 'n_b{/Symbol s}_n/{/Symbol s}_1', 
            xtics  => 25, 
            grid   => 1
        }, 

        # stderr 
        ( 
            with      => 'linespoint', 
            pointtype => 4,
            pointsize => 1,
            linecolor => [ rgb => $hcolor{ $color } ], 
            linewidth => 2, 
        ), $$bsize, $$SI
    ); 
} 

1
