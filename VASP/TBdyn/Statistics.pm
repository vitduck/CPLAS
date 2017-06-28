package VASP::TBdyn::Statistics; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures';  

use PDL; 
use PDL::Stats::Basic; 
use PDL::Graphics::Gnuplot; 

use VASP::TBdyn::Color; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    block_analysis
    write_SI
    plot_SI
); 

sub block_analysis ( $tserie, $bsize, $bvar, $SI ) { 
    my ( @block_sizes, @block_vars ); 

    for my $size ( 2 .. int( $$tserie->nelem / 4 ) ) { 
        my $nblock = int( $$tserie->nelem / $size ); 

        # work on a 'copy' of the original time serie
        # reshape is equivalent to bloking operation 
        my $block_avg = $$tserie->copy->reshape($size, $nblock)->daverage; 

        push @block_sizes, $size; 
        push @block_vars, $block_avg->var; 
    }

    # deref
    $$bsize = PDL->new( @block_sizes );  
    $$bvar  = PDL->new( @block_vars );  

    # statistical ineffeciency 
    $$SI = $$bsize * $$bvar / $$tserie->var; 

    # convenient coordinate: sqrt(n_b)
    $$bsize->inplace->sqrt; 
}

sub write_SI ( $bsize, $bvar, $SI, $output ) { 
    print "=> blocking analysis for $output\n";

    my $fh = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$SI->nelem -1 ) { 
        $fh->printf( 
            "%10.5f %10.5f %10.5f\n", 
            $$bsize->at($_),
             $$bvar->at($_),
               $$SI->at($_), 
        ) 
    }

    $fh->close; 
} 

sub plot_SI ( $cc, $bsize, $SI, $type ) { 
    my %symbol = ( 
        'gradient' => { 
            legend => '|z|^{-1/2}({/Symbol l} + GkT)', 
            color  => 'red'  
        }, 
        'potential' => { 
            legend  => '|z|^{-1/2}E_{pot}',  
            color   => 'blue' 
        }, 
    ); 

    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1, 
    ); 
    
    $figure->plot( 
        # plot options
        { 
            key    => 'top right spacing 2',
            title  => sprintf( 'Constrain {/Symbol x} = %.3f', $$cc->at(0) ),  
            xrange => sprintf( '%d:%d', $$bsize->min, $$bsize->max ), 
            xlabel => '{/Symbol=\326}n_b',
            ylabel => 'n_b{/Symbol s}_n / {/Symbol s}_1', 
        }, 

        ( 
            with      => 'linespoint', 
            dashtype  => 1,
            pointtype => 4,
            linewidth => 2, 
            linecolor => [ rgb => $hcolor{ $symbol{ $type }{ color } } ], 
            legend    => $symbol{ $type }{ legend },  
        ),$$bsize, $$SI, 
    );  
} 

1
