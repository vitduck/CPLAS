package Pes; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use File::Find; 
use VASP::OUTCAR; 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( pes ); 

sub pes ( $energy ) { 
    find( 
        sub {
            if ( /OUTCAR/ ) {  
                my $cc  = ( split /\//, $File::Find::name )[1]; 
                $cc     =~ s/d-//; 
                $energy->{ $cc } = VASP::OUTCAR->new->get_energy 
            } 
        }, '.'
    ); 
} 

1
