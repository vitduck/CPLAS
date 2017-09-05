package VASP::TBdyn::Statistics; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures';  

use PDL; 
use PDL::Stats::Basic; 
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot; 

use IO::KISS; 
use VASP::TBdyn::Color; 

our @ISA    = qw( Exporter ); 
our @EXPORT = qw( unbiased_avg block_err ensemble ); 

# ratio of two ensemble averages 
# here the term 1/N simply cancels out
sub unbiased_avg ( $z_12, $biased, $unbiased, $output ) { 
    my @unbiased;

    # sanity check
    die "Dimensional mismatch between z_12 and biased quantity\n" 
        unless $$z_12->nelem == $$biased->nelem; 
    
    my $Sz_12   = 0;  
    my $Sbiased = 0; 
    my $fh      = IO::KISS->new( $output, 'w' ); 
    
    for ( 0 .. $$z_12->nelem - 1 ) { 
        my $average; 

        $Sz_12   += $$z_12->at( $_ ); 
        $Sbiased += $$biased->at( $_ ); 
        $average  = $Sbiased / $Sz_12;  

        push @unbiased, $average; 

        $fh->printf( 
            "%d\t%10.7e\n", 
            $_+1, 
            $average 
        ); 
    }

    $fh->close; 

    # deref
    $$unbiased = PDL->new( @unbiased )
} 

sub block_err ( $thermo, $stderr, $output ) { 
    my @errs; 

    my $fh = IO::KISS->new( $output, 'w' ); 

    # minimum of 20 blocks data is requires
    # if the plateur doesn't appear, the simulation is to short
    for my $size ( 1 .. int( $$thermo->nelem / 20 ) ) { 
        my $nblock = int( $$thermo->nelem / $size ); 

        # work on a 'copy' of the original time serie
        # reshape(n,m) is equivalent to blocking: 
        # -n: block size 
        # -m: number of block 
        my $err = $$thermo->copy->reshape($size, $nblock)->daverage->se; 
        
        # print to file 
        $fh->printf( "%.5e\n", $err ); 

        push @errs, $err
    }

    $fh->close; 

    # deref
    $$stderr = PDL->new( @errs );  
}

sub ensemble ( $cc, $z_12, $thermo, $stderr, $output ) {   
    my $fh = IO::KISS->new( $output, 'w' ); 

    print "=> Correlation length for $output: "; 
    chomp ( my $nblock = <STDIN> ); 

    $fh->printf( 
        "%7.3f  %7.3f  %7.3f  %d\n", 
        $$cc->at(0), 
        $$thermo->avg / $$z_12->avg, 
        $$stderr->at( $nblock -1 ), 
        $nblock, 
    ); 

    $fh->close; 
} 

1
