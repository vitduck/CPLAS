package Gradient; 

use strict; 
use warnings; 
use experimental qw( signatures ); 

use File::Find; 
use IO::KISS;  

our @ISA    = 'Exporter'; 
our @EXPORT = qw( 
    read_report read_gradient read_gradients 
    acc_average trapezoidal
);  

sub read_report ( $file, $cc, $gradient ) { 
    my $report = IO::KISS->new( $file, 'r' ); 

    while ( local $_ = $report->get_line ) { 
        $$cc = (split)[2]               if /cc>/; 
        push $gradient->@*, (split)[-1] if /b_m>/ 
    } 
    $report->close; 
}

sub read_gradient ( $gradient ) { 
    find ( 
        sub { 
            if ( /^gradient.dat/ ) {  
                my $cc  = ( split /\//, $File::Find::name )[1]; 
                my $io = IO::KISS->new( $_, 'r' ); 
                while ( local $_ = $io->get_line ) { 
                    $gradient->{ $cc } = (split)[-1]; 
                }
            }
        }, '.'
    ); 
} 

sub read_gradients ( $file, $gradient ) { 
    for ( IO::KISS->new( $file, 'r' )->get_lines ) { 
        my ( $cc, $acc_average ) = split; 
        $gradient->{ $cc } = $acc_average;  
    } 
} 

sub acc_average ( $gradient, $average ) {  
    my $sum = 0;  
    my $io  = IO::KISS->new( 'gradient.dat', 'w' ); 

    for my $index ( 0..$gradient->$#* ) { 
        # accumlate averages 
        $sum += $gradient->[ $index ]; 

        # print to grdient.dat 
        $io->printf( 
            "%d\t%f\t%f\n", 
            $index + 1, 
            $gradient->[ $index ], 
            $sum / ( $index + 1 )
        );  

        # add to @averages 
        push $average->@*, $sum / ( $index + 1 ) 
    }
    $io->close; 

    # check convergence
    print "\n=> Convergence of <dA/ds>\n"; 
    for ( $gradient->$#* - 10 .. $gradient->$#* ) { 
        printf "%d\t%f\t%f\n", $_+1, $gradient->[$_], $average->[$_]; 
    }
} 

sub trapezoidal ( $gradient, $trapz ) { 
    my @cc  = sort { $a <=> $b } keys $gradient->%*; 
        
    # first point 
    $trapz->{ $cc[0] } = 0; 

    my $sum = 0; 
    for my $index ( 0..$#cc - 1 ) { 
        my $h = $cc[ $index+1 ] - $cc[ $index ]; 
        $sum += 0.5 * $h * ( $gradient->{ $cc[ $index ] } + $gradient->{ $cc[ $index+1 ] } ); 
        $trapz->{ $cc[$index+1] } = $sum; 
    } 
} 

1
