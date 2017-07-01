package VASP::TBdyn::Statistics; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures';  

use PDL; 
use PDL::Stats::Basic; 
use PDL::NiceSlice;
use PDL::Stats::TS; 
use PDL::Graphics::Gnuplot; 

use VASP::TBdyn::Color; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    block_analysis
    coarse_grained
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

sub coarse_grained ( $cc, $z_12, $tserie, $output ) { 
    my $fh = IO::KISS->new( $output, 'w' ); 

    printf "=> Coarse-graining (%s): ", $output; 
    chomp ( my $SI = <STDIN> );  

    # round-up
    $SI = sprintf "%.0f", $SI; 
    
    # one value per rela;
    my $CS_z_12   =   $$z_12( :-1:$SI );  
    my $CS_tserie = $$tserie( :-1:$SI );  
    my $CS_grad   = $CS_tserie / $CS_z_12; 

    # the stderr of z_12 is small, and can be ignored
    $fh->printf( 
        "%7.3f  %10.5f  %10.5f\n", 
        $$cc->at(0), 
        $CS_grad->avg,
        $CS_tserie->se
    ); 

    $fh->close; 
} 

sub write_SI ( $bsize, $bvar, $SI, $output ) { 
    my $fh = IO::KISS->new( $output, 'w' ); 
    
    for ( 0..$$SI->nelem -1 ) { 
        $fh->printf( 
            "%7.3f  %10.5f  %10.5f\n", 
            $$bsize->at($_), 
             $$bvar->at($_), 
               $$SI->at($_) 
        ) 
    }

    $fh->close; 
} 

sub plot_SI ( $cc, $bsize, $SI, $type ) { 
    my %plot = ( 
        'pmf' => { 
            title => '|z|^{-1/2} * ({/Symbol l} + GkT)', 
            color => 'red',   
            pt    => 4, 
        }, 
        'epot' => { 
            title => '|z|^{-1/2} * E_{pot}',  
            color => 'blue', 
            pt    => 6, 
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
            key    => 'top left spacing 2',
            title  => sprintf( "$plot{ $type }{ title }  ({/Symbol x} = %.3f)", $$cc->at(0) ),  
            xrange => [ $$bsize->min, $$bsize->max ],
            xlabel => '{/Symbol=\326}n_b',
            ylabel => 'n_b{/Symbol s}_n / {/Symbol s}_1', 
            size   => 'ratio 0.75', 
            grid   => 1
        }, 

        # statistical inefficiency
        ( 
            with      => 'point', 
            pointtype => $plot{ $type }{ pt }, 
            linecolor => [ rgb => $hcolor{ $plot{ $type }{ color } } ], 
        ), $$bsize, $$SI, 
        
        # moving average
        ( 
            with      => 'lines', 
            dashtype  => 1,
            linewidth => 3, 
            linecolor => [ rgb => $hcolor{ white } ], 
        ), $$bsize, $$SI->filter_ma( 3 ), 
    );  
} 

1
