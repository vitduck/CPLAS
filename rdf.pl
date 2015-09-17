#!/usr/bin/env perl 

use strict; 
use warnings; 

use List::Util qw( min ); 
use Getopt::Long;  
use Pod::Usage; 

use GenUtil qw( read_line ); 
use Math    qw( triple_product ); 
use VASP    qw( read_cell read_geometry ); 
use XYZ     qw( make_box make_label make_xyz atom_distance ); 

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
my $line = read_line($input); 

# cell parameters
my ($scaling, $lat, $atom, $natom, $type) = read_cell($line);

# atomic positions
my $coordinate = read_geometry($line);

# reference unitcell
my $center = 1; 
my @nxyz   = (1,1,1); 
my ($nx, $ny, $nz, $ntotal) = make_box($natom, @nxyz); 
my $label = make_label($atom, $natom, @nxyz); 

# unitcell.xyz
my $fh = IO::File->new($unitcell, 'w') or die "Cannot write to $unitcell\n";  
printf $fh "%d\n\n", $ntotal;
my @ref_xyz = make_xyz($fh, $scaling, $lat, $label, $type, $coordinate, $center, $nx, $ny, $nz); 
$fh->close; 

# Fake PBC 
my $fx = $radius/sqrt($lat->[0][0]**2 + $lat->[0][1]**2 + $lat->[0][2]**2) + 1; 
my $fy = $radius/sqrt($lat->[1][0]**2 + $lat->[1][1]**2 + $lat->[1][2]**2) + 1; 
my $fz = $radius/sqrt($lat->[2][0]**2 + $lat->[2][1]**2 + $lat->[2][2]**2) + 1; 

# duplicate the box
($nx, $ny, $nz, $ntotal) = make_box($natom, 2*$fx+1, 2*$fy+1, 2*$fz+1); 
$label = make_label($atom, $natom, 2*$fx+1,2*$fy+1,2*$fz+1); 
$nx = [-$fx..$fx]; 
$ny = [-$fy..$fy]; 
$nz = [-$fz..$fz]; 

# supercell.xyz
$fh = IO::File->new($supercell, 'w') or die "Cannot write to $supercell\n";  

printf $fh "%d\n\n", $ntotal; 
my @sup_xyz = make_xyz($fh, $scaling, $lat, $label, $type, $coordinate, $center, $nx, $ny, $nz);  

# close file handler 
$fh->close; 

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
my $vcell  = triple_product($lat->[0], $lat->[1], $lat->[2]); 

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
