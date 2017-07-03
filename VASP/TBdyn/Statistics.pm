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
    block_average
    write_stat
    write_stderr
    plot_stderr
); 

sub block_average ( $thermo, $bse ) { 
    my @bses; 

    # minimum of 20 blocks data is requires
    # if the plateur doesn't appear, the simulation is to short
    for my $size ( 1 .. int( $$thermo->nelem / 20 ) ) { 
        my $nblock = int( $$thermo->nelem / $size ); 

        # work on a 'copy' of the original time serie
        # reshape(n,m) is equivalent to blocking: 
        # -n: block size 
        # -m: number of block 
        my $bavg = $$thermo->copy->reshape($size, $nblock)->daverage; 

        push @bses, $bavg->se;  
    }

    # deref
    $$bse   = PDL->new( @bses );  
}

sub write_stderr ( $pmf_stderr, $epot_stderr, $output ) { 
    # sanity check
    die "Mismatch between pmf and potential\n"
        unless $$pmf_stderr->nelem == $$epot_stderr->nelem; 

    my $fh = IO::KISS->new( $output, 'w' ); 
    for ( 0..$$pmf_stderr->nelem -1 ) { 
        $fh->printf( "%d  %10.5f  %10.5f\n", $_+1, $$pmf_stderr->at($_), $$epot_stderr->at($_) )
    }
    $fh->close; 
} 

sub write_stat ( $cc, $z_12, $thermo, $stderr, $output ) {   
    my $fh = IO::KISS->new( $output, 'w' ); 

    print "=> Block length for $output: "; 
    chomp ( my $nblock = <STDIN> ); 

    $fh->printf( 
        "%7.3f  %d  %7.3f  %7.3f\n", 
        $$cc->at(0), 
        $nblock, 
        $$thermo->avg / $$z_12->avg, 
        $$stderr->at( $nblock -1 )
    ); 

    $fh->close; 
} 

sub plot_stderr ( $cc, $stderr, $type ) { 
    # x-axis
    my $bsize = PDL->new( 1..$$stderr->nelem ); 

    # type table
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
            #xlabel => '{/Symbol=\326}n_b',
            #ylabel => 'n_b{/Symbol s}_n / {/Symbol s}_1', 
            xlabel => 'n_b',
            ylabel => 'standard error', 
            size   => 'ratio 0.75', 
            grid   => 1
        }, 

        # standard error 
        ( 
            with      => 'point', 
            linewidth => 2,
            pointtype => $plot{ $type }{ pt }, 
            linecolor => [ rgb => $hcolor{ $plot{ $type }{ color } } ], 
        ), $bsize, $$stderr, 
        
        # moving average
        ( 
            with      => 'lines', 
            dashtype  => 1,
            linewidth => 3, 
            linecolor => [ rgb => $hcolor{ white } ], 
        ), $bsize, $$stderr->filter_ma( 3 ), 
    );  
} 

1
