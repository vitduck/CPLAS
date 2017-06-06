package VASP::TBdyn::Report; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_report 
); 

sub read_report ( $cc, $z_12, $lpGkT, $e_pot, $equilibration = 500 ) { 
    my ( @cc, @z_12, @lpGkT, @e_pots );  

    my $report = IO::KISS->new( 'REPORT', 'r' ); 

    while ( local $_ = $report->get_line ) { 
        # constraint 
        if ( /cc>/  ) { 
            push @cc, ( split )[2] 
        } 

        # bluemoon stuff
        if ( /b_m>/ ) {  
            my @bm = split; 
            push @z_12,  $bm[ 2]; 
            push @lpGkT, $bm[-1]; 
        }

        # potential energy 
        if ( /e_b>/ ) {  
            push @e_pots,  (split)[2]
        }

    } 

    $report->close; 

    # equilibrartion ( !? ) 
    map { splice @$_, 0, $equilibration } ( \@cc, \@z_12, \@lpGkT, \@e_pots ); 

    # deref the piddle
    $$cc    = PDL->new( @cc    ); 
    $$z_12  = PDL->new( @z_12  ); 
    $$lpGkT = PDL->new( @lpGkT ); 
    $$e_pot = PDL->new( @e_pots ); 
    
    # z^-1/2 x E_pot  (unlike lpGkT) 
    $$e_pot = $$e_pot * $$z_12; 
}

1; 
