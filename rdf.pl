#!/usr/bin/env perl 

use strict; 
use warnings; 

use List::Util qw( min ); 
use Getopt::Long;  
use Pod::Usage; 

use GenUtil qw( read_line ); 
use Math    qw( triple_product ); 
use VASP    qw( read_cell read_geometry ); 
use XYZ     qw( make_supercell make_xyz atom_distance ); 

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
my (@distances, %gr, %gr_gaussian); 

# parse optional arguments 
GetOptions(
    'h'   => \$help, 
    'a=s' => \$atm1, 
    'b=s' => \$atm2, 
    'r=f' => \$radius
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# default options to be defined
unless ( defined $atm1 and defined $atm2 and defined $radius ) {  
    pod2usage(-verbose => 1); 
}

# input & output
my $input     = 'CONTCAR'; 
my $unitcell  = 'unitcell.xyz'; 
my $supercell = 'supercell.xyz'; 

# CONTCAR lines 
my @lines = read_line($input); 

# cell parameters
my ($scaling, $r2lat, $r2atom, $r2natom, $type) = read_cell(\@lines);

# atomic positions
my @coordinates = read_geometry(\@lines);

# reference unitcell
my $centralized = 1; 
my @nxyz = (1,1,1); 

# scalar -> array ref! 
my ($nx, $ny, $nz) = map { [0..$_-1] } @nxyz; 

# supercell parameters 
my ($label, $natom, $ntotal) = make_supercell($r2atom, $r2natom, $nx, $ny, $nz); 

# unitcell.xyz
open my $fh, '>', $unitcell; 
printf $fh "%d\n\n", $ntotal;
my @ref_xyz = make_xyz($fh, $scaling, $r2lat, $label, $type, \@coordinates, $centralized, $nx, $ny, $nz); 
close $fh; 

# Fake PBC 
$nx = $radius/sqrt($r2lat->[0][0]**2 + $r2lat->[0][1]**2 + $r2lat->[0][2]**2) + 1; 
$ny = $radius/sqrt($r2lat->[1][0]**2 + $r2lat->[1][1]**2 + $r2lat->[1][2]**2) + 1; 
$nz = $radius/sqrt($r2lat->[2][0]**2 + $r2lat->[2][1]**2 + $r2lat->[2][2]**2) + 1; 

my $px = [-$nx..$nx]; 
my $py = [-$ny..$ny]; 
my $pz = [-$nz..$nz]; 

# supercell parameters 
my ($slabel, $snatom, $sntotal) = make_cell($r2atom, $r2natom, $px, $py, $pz); 

# supercell.xyz 
open $fh, '>', $supercell; 
printf $fh "%d\n\n", $sntotal;
my @sup_xyz = make_xyz($fh, $scaling, $r2lat, $slabel, $type, \@coordinates, $centralized, $px, $py, $pz); 
# close file handler 
close $fh; 

# list grep
my @atm1 = grep { $_->[0] =~ /$atm1/i } @ref_xyz; 
my @atm2 = grep { $_->[0] =~ /$atm2/i } @sup_xyz; 

# radius grid  based on faked PBC
$ngrid    *= int(min($nx, $ny, $nz)); 
my $dgrid  = $radius/$ngrid; 
my @radius = map { ($radius/$ngrid)*$_ } 0..$ngrid-1; 

# initialization %gr 
map { $gr{$_} = 0 } @radius; 

# pair distance 
for my $atm1 ( @atm1 ) { 
    for my $atm2 ( @atm2 ) { 
        my $d12 = atom_distance($atm1, $atm2); 
        # do not count itself 
        next if $d12 == 0 or $d12 > $radius; 
        # asign to approriate grid 
        my $index = int($d12/$dgrid); 
        $gr{$radius[$index]} += 1;  
    }
}

# dirac -> normalized gaussian 
my $sigma = 1.e-2; 
my $pi    = 3.14159265;
my $norm  = 1/sqrt($sigma*$pi); 
for my $r1 ( sort { $a <=> $b } keys %gr ) { 
    for my $r2 ( sort { $a <=> $b } keys %gr ) { 
        $gr_gaussian{$r2} += $gr{$r1} * exp(-($r1-$r2)**2/$sigma) 
    }
}

# normalized gaussian distribution 
map { $gr_gaussian{$_} *= $norm } keys %gr_gaussian; 

# normalized g(r) by particle density within spherical shell 
my $dr     = 0.5*$radius/$ngrid; 
my $ncoord = 0; 
# number of reference particle
my $N1     = scalar(@atm1); 
my $N2     = scalar(grep { $_->[0] =~ /$atm2/i } @ref_xyz); 
my $vcell  = triple_product($r2lat->[0], $r2lat->[1], $r2lat->[2]); 

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
