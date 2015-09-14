#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use GenUtil  qw ( read_line ); 
use VASP     qw ( read_cell read_geometry ); 
use XYZ      qw ( make_supercell make_xyz xmakemol ); 

my @usages = qw ( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
contcar.pl: convert CONTCAR to contcar.xyz

=head1 SYNOPSIS

contcar.pl [-h] [-i] <CONTCAR> [-c] [-q] [-x nx ny nz]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

Input file (default: CONTCAR) 

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=back

=cut

# default args
my @nxyz        = (); 
my $help        = 0; 
my $centralized = 0; 
my $quiet       = 0; 

# input & output
my $input  = 'CONTCAR'; 
my $output = 'contcar.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input,
    'c'      => \$centralized, 
    'q'      => \$quiet, 
    'x=i{3}' => \@nxyz, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# CONTCAR lines
my @lines = read_line($input); 

# cell parameters 
my ($scaling, $r2lat, $r2atom, $r2natom, $type) = read_cell(\@lines); 

# atomic positions 
my @coordinates = read_geometry(\@lines); 

# contcar.xyz
open my $fh, '>', $output; 

# default supercell expansion
unless ( @nxyz == 3 ) { @nxyz = (1, 1, 1) }

# scalar to array ref 
my ($nx, $ny, $nz) = map { [0..$_-1] } @nxyz; 

# supercell parameters 
my ($label, $natom, $ntotal) = make_supercell($r2atom, $r2natom, $nx, $ny, $nz); 

# contcar.xyz
printf $fh "%d\n\n", $ntotal; 

my @xyz = make_xyz($fh, $scaling, $r2lat, $label, $type, \@coordinates, $centralized, $nx, $ny, $nz); 

# flush
close $fh; 

# xmakemol
xmakemol($output, $quiet); 
