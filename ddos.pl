#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use Math::Linalg qw( length ); 
use VASP qw( :doscar read_poscar ); 
use XYZ  qw ( tag_xyz ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

ddos.pl: extract projected DOS from DOSCAR 

=head1 SYNOPSIS

ddos.pl [-h] [-i] <POSCAR> [-p 1 2] [-s LDOS-1.dat] [-l s p d]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: DOSCAR)

=item B<-p> 

list of projected DOS to be extracted 

=item B<-s> 

files/columns LDOS summation 

=item B<-l> 

list of orbitals for column summation (default: s p d f)

=back 

=cut 

# default optional arguments
my $help   = 0; 
my $input  = 'DOSCAR'; 
my @projs  = (); 
my @sum    = (); 
my @lorbit = (); 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input, 
    'p=s{1,}' => \@projs, 
    's=s{1,}' => \@sum, 
    'l=s{1,}' => \@lorbit, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# projected dos 
@projs && do { 
    my %dos = read_doscar('DOSCAR'); 

    # atomic tag 
    my @tag = ();  
    if ( -e 'POSCAR' ) { 
        my %poscar = read_poscar('POSCAR'); 
        @tag = tag_xyz($poscar{atom}, $poscar{natom}, [[0],[0],[0]]);  
    }

    # format digit 
    my $ndigit = length(@projs); 

    for my $atom ( @projs ) { 
        my $output; 

        # 0: total DOS 
        if ( $atom == 0 ) { 
            $output = 'TDOS.dat';    
        # n: projected DOS 
        } else { 
            my $prefix = ( @tag == 0 ? 'LDOS' : $tag[$atom-1] );
            $output = sprintf("$prefix-%0${ndigit}d.dat", $atom); 
        }
        
        print "=> $output\n"; 
        print_ldos($dos{$atom} => $output); 
    }

    exit; 
}; 

# sum dos 
@sum && do { 
    # column summation 
    if ( @sum == 1 ) { 
        # default lrobit 
        if ( @lorbit == 0 ) { @lorbit = qw( s p d f ) } 
        
        # output 
        my $prefix = $1 if $sum[0] =~ /^(.+?)\.dat/; 
        my $csum = "$prefix-".(join '', @lorbit).'.dat';  
        print "=> $sum[0]: @lorbit summation to $csum\n"; 

        sum_ldos_cols( $sum[0], \@lorbit => $csum ); 
    } else { 
        my $fsum = 'SUMDOS.dat'; 
        print "=> LDOS summation to $fsum\n"; 

        sum_ldos_files(\@sum => $fsum); 
    }

    exit; 
}
