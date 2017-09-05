package VASP::TBdyn::Report; 

use autodie; 
use strict; 
use warnings; 
use experimental 'signatures'; 

use PDL; 
use IO::KISS; 

our @ISA    = qw( Exporter    ); 
our @EXPORT = qw( read_report ); 

sub read_report ( $cc, $z_12, $z_12xlGkT, $z_12xEpot, $equilibration = 0 ) { 
    my ( @cc, @z_12, @z_12xlGkT, @Epot );  

    my $report = IO::KISS->new( 'REPORT', 'r' ); 

    while ( local $_ = $report->get_line ) { 
        # constraints
        if ( /cc>/ ) { 
            push @cc, (split)[2] 
        } 

        # bluemoon statistics
        if ( /b_m>/ ) {  
            my @bm = split; 
            push @z_12,      $bm[ 2]; 
            push @z_12xlGkT, $bm[-1]; 
        }

        # potential energy 
        if ( /e_b>/ ) {  
            push @Epot, (split)[2]
        }
    } 

    $report->close; 

    # equilibrartion ( !? ) 
    map { splice @$_, 0, $equilibration } ( \@cc, \@z_12, \@z_12xlGkT, \@Epot ); 

    # deref the piddle
    $$cc        = PDL->new( @cc        ); 
    $$z_12      = PDL->new( @z_12      ); 
    $$z_12xlGkT = PDL->new( @z_12xlGkT ); 
    $$z_12xEpot = PDL->new( @Epot      ) * $$z_12; 
}

1; 
