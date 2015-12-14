#!/usr/bin/perl 

use strict; 
use warnings; 

use Getopt::Long; 
use IO::File; 
use Pod::Usage; 

use VASP qw( read_poscar read_final_magmom ); 
use XYZ  qw(direct_to_cartesian print_cartesian set_pbc color_magmom tag_xyz xmakemol );  

my @usages = qw/NAME SYSNOPSIS OPTIONS/;  

# POD 
=head1 NAME 
contcar.pl: convert CONTCAR to poscar.xyz

=head1 SYNOPSIS

contcar.pl [-h] [-i] <CONTCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-q] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: POSCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=item B<-m> 

Show initial MAGMOM

=back

=cut

# default optional arguments
my $help   = 0; 
my $input  = 'CONTCAR'; 
my @dxyz   = ();  
my @nxyz   = ();  
my $quiet  = 0; 
my %mode   = ();  

my $xyz    = 'contcar.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input, 
    'q'      => \$quiet, 
    'd=f{3}' => \@dxyz,  
    'c'      => sub { @dxyz = (0.5,0.5,0.5) },  
    'x=i{3}' => sub { push @nxyz, [0..$_[1]-1] },  
    'm'      => sub { $mode{magmom} = [ read_final_magmom('OUTCAR') ] }, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# read CONTCAR
my %contcar = read_poscar($input); 

# pbc box 
@nxyz = ( @nxyz == 0 ? ([0], [0], [0]) : @nxyz );  

# tag  
my @tags = tag_xyz($contcar{atom}, $contcar{natom}, \@nxyz, \%mode);  

# print coordinate to contcar.xyz
open my $fh, '>', $xyz or die "Cannot write to $xyz\n"; 
my @xyz = direct_to_cartesian($contcar{cell}, $contcar{geometry}, \@dxyz, \@nxyz); 
print_cartesian($contcar{name}, \@tags, \@xyz => $fh);
close $fh; 

# xmakemol
xmakemol($quiet, $xyz); 
