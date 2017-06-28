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
    my $nelem = $$tserie->nelem; 
    
    my $min_block_size = 2; 
    my $max_block_size = int( $nelem / 20 ); 
    
    my ( @block_sizes, @block_vars ); 
    
    for my $size ( $min_block_size .. $max_block_size ) { 
        my $nblock    = int( $nelem / $size ); 

        # work on a 'copy' of the original time serie
        # reshape is equivalent to bloking operation 
        my $block_avg = $$tserie->copy->reshape($size, $nblock)->daverage; 
        
        push @block_sizes, $size; 
        push @block_vars, $block_avg->var; 

   }

    $$bsize = PDL->new( @block_sizes ); 
    $$bvar  = PDL->new( @block_vars  ); 

    # statistical ineffeciency 
    $$SI = $$bsize * $$bvar / $$tserie->var; 

    # convinient coordinate sqrt(n_b) 
    $$bsize->inplace->sqrt; 
}

sub write_SI ( $bsize, $SI, $output ) { 
    print "=> blocking analysis for $output\n";

    my $io = IO::KISS->new( $output, 'w' ); 

    for ( 0..$$bsize->nelem -1 ) { 
        $io->printf( 
            "%10.5f %10.5f\n", 
            $$bsize->at($_),   
            $$SI->at($_) 
        ) 
    }

    $io->close; 
} 

sub plot_SI ( $cc, $bsize, $bvar, $SI, $title, $color='red' ) { 
    my %symbol = ( 
        'grad' => '|z|^{-1/2}({/Symbol l} + GkT)', 
        'pot'  => '|z|^{-1/2}E_{pot}'
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
            title  => sprintf( '%s  ({/Symbol x} = %.3f)', $symbol{$title}, $$cc->at(0) ),  
            xrange => sprintf( '%d:%d', $$bsize->min, $$bsize->max ), 
            xlabel => '{/Symbol=\326}n_b',
            ylabel => 'n_b{/Symbol s}_n / {/Symbol s}_1', 
        }, 

        # stderr 
        ( 
            with      => 'linespoint', 
            dashtype  => 1,
            pointtype => 4,
            linewidth => 2, 
            linecolor => [ rgb => $hcolor{ $color } ], 
            legend    => 'Statistical Ineffeciency'
        ), $$bsize, $$SI
    ); 
} 

1
