#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long;  
use Pod::Usage; 

use Math::Linalg qw( min norm triple ); 
use VASP qw( read_poscar ); 
use Util qw( read_file ); 
use XYZ qw( tag_xyz direct_to_cartesian print_cartesian distance ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
rdf.pl: calculate pair correlation function from CONTCAR 

=head1 SYNOPSIS

rdf.pl [-h] [-a atm1] [-b atm2] [-r 10] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-a> 

The reference atom of constructed sphere 

=item B<-b> 

The atom to be counted within the sphere 

=item B<-r> 

Radius of the sphere 

=back 

=cut 

# default optional arguments
my $help = 0; 
my ($atm1, $atm2, $radius);  
my $ngrid  = 500; 

# parse optional arguments 
GetOptions(
    'h'   => \$help, 
    'a=s' => \$atm1, 
    'b=s' => \$atm2, 
    'r=f' => \$radius
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# forced $atm1, $atm2 and $radius to be defined by user
if ( (grep defined $_, ($atm1, $atm2, $radius)) != 3 ) { pod2usage(-verbose => 1) } 

# read geometry
my $input = 'CONTCAR'; 
my %ref   = read_poscar('CONTCAR'); 

# reference unitcell
my $unitcell  = 'unitcell.xyz'; 
my @unit_tags = tag_xyz($ref{atom}, $ref{natom}, [[0],[0],[0]]);  
my @unit_xyz  = direct_to_cartesian($ref{cell}, $ref{geometry}, [], [[0],[0],[0]]); 

# Fake PBC box 
my $fnx  = $radius/norm($ref{cell}[0])+1; 
my $fny  = $radius/norm($ref{cell}[1])+1; 
my $fnz  = $radius/norm($ref{cell}[2])+1; 
my @fxyz = ( [-$fnx..$fnx], [-$fny..$fny],[-$fnz..$fnz] ); 

# supercell 
my $supercell  = 'supercell.xyz'; 
my @super_tags = tag_xyz($ref{atom}, $ref{natom}, \@fxyz); 
my @super_xyz  = direct_to_cartesian($ref{cell}, $ref{geometry}, [], \@fxyz); 

# list grep
my @unit_indices  = grep { $unit_tags[$_] eq $atm1 } 0..$#unit_tags;  
my @super_indices = grep { $super_tags[$_] eq $atm2 } 0..$#super_tags;  

# radius grid  based on faked PBC
$ngrid *= int(min($fnx, $fny, $fnz)); 
my $dgrid  = $radius/$ngrid;  
my @radius = map { ($radius/$ngrid)*$_ } 0..$ngrid-1; 

# initialization %gr 
my %gr = map { $_, 0 } @radius; 

# pair distance 
for my $i ( @unit_indices ) { 
   for my $j ( @super_indices ) { 
        my $d12 = distance($unit_xyz[$i], $super_xyz[$j]); 
        # do not count itself 
        if ( $d12 == 0 or $d12 >= $radius ) { next } 
        # asign to approriate grid 
        my $index = int($d12/$dgrid); 
        $gr{$radius[$index]} += 1;  
    } 
}

# dirac -> normalized gaussian 
my $sigma = 1.e-2; 
my $pi    = 3.14159265;
my $norm  = 1/sqrt($sigma*$pi); 
my %gr_gaussian; 
for my $r1 ( sort { $a <=> $b } keys %gr ) { 
    for my $r2 ( sort { $a <=> $b } keys %gr ) { 
        $gr_gaussian{$r2} += $gr{$r1} * exp(-($r1-$r2)**2/$sigma) 
    }
}

# normalized gaussian distribution 
map { $_ *= $norm } values %gr_gaussian; 

# normalized g(r) by particle density within spherical shell 
my $dr     = 0.5*$radius/$ngrid; 
my $ncoord = 0; 

# number of reference particle
my $N1     = scalar(@unit_indices); 
my $N2     = scalar(grep { $unit_tags[$_] eq $atm2 } @unit_indices); 
my $vcell  = triple(@{$ref{cell}}); 

# output 
my $output    = "$atm1-$atm2.dat"; 
open OUTPUT, '>', $output or die "Cannot write to $output\n"; 
for my $r ( sort { $a <=> $b } keys %gr_gaussian ) {
    my $surface = 4.0*$pi*($r+$dr)**2; 
    my $volume  = (4.0/3)*$pi*($r+$dr)**3; 
    my $correlation = (($vcell/$surface)/($N1*$N2))*$gr_gaussian{$r}; 
    # number of coordination 
    $ncoord += $correlation*$surface/$volume;
    printf OUTPUT "%10.5f\t%10.5f\t%10.5f\n", $r+$dr, $correlation, $ncoord;  
}
close OUTPUT; 
