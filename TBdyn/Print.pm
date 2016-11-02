package Print; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use File::Find; 
use IO::KISS; 

our @ISA       = 'Exporter'; 
our @EXPORT    = qw( print_hash shift_hash ); 

sub print_hash ( $hash, $output ) { 
    print "=> $output\n"; 
    my $io = IO::KISS->new( $output, 'w' ); 
    for ( sort { $a <=> $b } keys $hash->%* ) { 
        $io->printf( "%f\t%f\n", $_, $hash->{ $_ } )
    } 
    $io->close; 
} 

sub shift_hash ( $hash, $index ) { 
    my @keys = sort { $a <=> $b } keys $hash->%*; 
    my $ref  = $hash->{ $keys[ $index ] }; 

    for ( @keys ) { 
        $hash->{ $_ } -= $ref
    } 
} 

1
