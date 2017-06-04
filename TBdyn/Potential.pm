 package Potential; 

use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use PDL::Stats::Basic; 
use PDL::Graphics::Gnuplot; 

use IO::KISS; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_potential 
);

sub read_potential ( $z_12, $e_pot, $nequilibrium = 0 ) { 
    my ( @z_12, @e_pots );  

    my $report = IO::KISS->new( 'REPORT', 'r' ); 

    while ( local $_ = $report->get_line ) { 
        # blue_moon ensemble 
        if ( /b_m/ ) {  
            push @z_12,  (split)[2]
        }
        
        # biased potential 
        if ( /e_b>/ ) {  
            push @e_pots,  (split)[2]
        }
    } 

    $report->close; 

    # equilibrartion 
    map { splice @$_, 0, $nequilibrium } ( \@z_12, \@e_pots ); 

    # deref the piddle
    $$z_12  = PDL->new( @z_12  ); 
    $$e_pot = PDL->new( @e_pots ); 

    # z^-1/2 x E_pot   
    $$e_pot = $$e_pot * $$z_12; 
}

1
