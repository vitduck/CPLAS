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
    block_average
    write_stderr 
    plot_stderr
); 

sub block_average ( $z_12, $H, $bsize, $bavg, $bstdv, $bstde ) { 
    my $nelem = $$z_12->nelem; 
    
    my $min_block_size = 1; 
    my $max_block_size = int( $nelem / 4 ); 

    my ( @bsize, @bavg, @bstdv, @bstde ); 
    
    for my $size ( $min_block_size .. $max_block_size ) { 
        my @avg; 
        
        my $lb     = 0; 
        my $rb     = 0; 
        my $nblock = int( $nelem / $size ); 

        for ( 1 .. $nblock ) { 
            $rb = $lb + $size - 1; 

            push @avg, $$H->slice( "$lb:$rb" )->sum / $$z_12->slice( "$lb:$rb" )->sum; 
                
            # shift left bound
            $lb += $size; 
       } 

        my $avg = PDL->new( @avg ); 

        push @bsize, $size; 
        push @bavg,  $avg->average; 
        push @bstdv, $avg->stdv; 
        push @bstde, $avg->se
    }

    $$bsize = PDL->new( @bsize ); 
    $$bavg  = PDL->new( @bavg  ); 
    $$bstdv = PDL->new( @bstdv ); 
    $$bstde = PDL->new( @bstde ); 
}

sub write_stderr ( $cc, $bsize, $bavg, $bstdv, $bstde, $output ) { 
    my $io = IO::KISS->new( $output, 'w' ); 

    print "=> Correlation length for $output: "; 
    chomp ( my $corr_length = <STDIN> ); 

    # header
    $io->printf( "# Constraint: %7.3f\n", $$cc->uniq->at(0) ); 
    $io->printf( "# Correlation length: %d steps\n", $corr_length  ); 

    for ( 0..$$bsize->nelem -1 ) { 
        $io->printf(
            "%d %10.5f %10.5f %10.5f\n", 
            $$bsize->at( $_ ),  
             $$bavg->at( $_ ),  
            $$bstdv->at( $_ ),  
            $$bstde->at( $_ ),  
        )
    }
    
    $io->close; 
} 

sub plot_stderr ( $cc, $bsize, $bstde, $title = 'Statistics', $color='red' ) { 
    my $figure = gpwin( 
        'x11', 
        persist  => 1, 
        raise    => 1, 
        enhanced => 1 
    ); 

    $figure->plot( 
        # plot options
        { 
            title  => sprintf( '%s (cc = %f)', $title, $$cc->at(0) ),  
            xlabel => 'Block size', 
            ylabel => '{/Symbol s}', 
            grid   => 1
        }, 

        # stderr 
        ( 
            with      => 'lines', 
            linecolor => [ rgb => $hcolor{ $color } ], 
            linewidth => 2, 
        ), $$bsize, $$bstde
    ); 
} 

1
