#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Dumper; 
use Getopt::Long; 
use IO::File; 
use Pod::Usage; 

use Math::Linalg qw( sum product dot mat_mul );   
use VASP    qw( read_poscar read_phonon ); 
use XYZ     qw( tag_xyz direct_to_cartesian xmakemol ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
eigenvec.pl: visualize atomic displacement 

=head1 SYNOPSIS

eigenvec.pl [-h] [-c] [-s 0.5] [-m 1] [-f 10] [-q] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-s> 

Scaling of the displacement vector 

=item B<-m> 

Eigenmode 

=item B<-f> 

Number of animation steps 

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help  = 0; 
my $scale = 0.25; 
my $mode  = 0; 
my $freq  = 10; 
my @dxyz  = ();  
my @nxyz  = ();  
my $quiet = 0;  

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    's=f'    => \$scale, 
    'm=i'    => \$mode, 
    'f=f'    => \$freq, 
    'c'      => sub { @dxyz = (0.5,0.5,0.5) }, 
    'd=f{3}' => \@dxyz,  
    'q'      => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help or $mode == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# read poscar 
my %poscar = read_poscar('POSCAR'); 

# pbc box 
@nxyz = ( @nxyz == 0 ? ([0], [0], [0]) : @nxyz );  

# read eigen{vector,value}
my %eigen = read_phonon('OUTCAR'); 

# direct to cartesian 
my @tags = tag_xyz($poscar{atom}, $poscar{natom}, \@nxyz); 
my @cartesian = direct_to_cartesian($poscar{cell}, $poscar{geometry}, \@dxyz, \@nxyz); 

# output 
my $output = "$mode.xyz"; 
open my $fh, '>', $output or die "Cannot open $output\n"; 

for my $nstep (0..$freq) { 
    printf $fh "%d\n%f\n", scalar(@cartesian), $eigen{$mode}[0];   
    for my $natom ( 0..$#cartesian ) { 
        my ($x, $y, $z) = @{$cartesian[$natom]}[0..2]; 
        $x += $nstep*$scale*$eigen{$mode}[$natom+1][0]/$freq; 
        $y += $nstep*$scale*$eigen{$mode}[$natom+1][1]/$freq; 
        $z += $nstep*$scale*$eigen{$mode}[$natom+1][2]/$freq; 
        printf $fh "%-3s %10.3f %10.3f %10.3f\n", $tags[$natom], $x, $y, $z; 
    }
}

close $fh; 

# visualize 
if ( $quiet == 0 ) { xmakemol($output) } 
