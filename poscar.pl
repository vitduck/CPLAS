#!/usr/bin/perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use GenUtil  qw ( read_line ); 
use VASP     qw ( read_cell read_geometry ); 
use XYZ      qw ( make_box make_label make_xyz xmakemol );

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
poscar.pl: convert POSCAR to poscar.xyz

=head1 SYNOPSIS

poscar.pl [-h] [-i] <POSCAR> [-c] [-q] [-x nx ny nz]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: POSCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=back

=cut

# default optional arguments 
my $help   = 0; 
my $center = 0; 
my $quiet  = 0; 
my @nxyz   = (1,1,1); 

# input & output
my $input  = 'POSCAR'; 
my $output = 'poscar.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input, 
    'c'      => \$center, 
    'q'      => \$quiet, 
    'x=i{3}' => sub { 
        my ($opt, $arg) = @_; 
        shift @nxyz; 
        push @nxyz, $arg; 
    }
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# POSCAR lines
my $line = read_line($input); 

# cell parameters 
my ($scaling, $lat, $atom, $natom, $type) = read_cell($line); 

# atomic positions 
my $coordinate = read_geometry($line); 

# supercell box
my ($nx, $ny, $nz, $ntotal) = make_box($natom, @nxyz); 

# xyz label 
my $label = make_label($atom, $natom, @nxyz); 

# poscar.xyz
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  

printf $fh "%d\n\n", $ntotal; 
my @xyz = make_xyz($fh, $scaling, $lat, $label, $type, $coordinate, $center, $nx, $ny, $nz); 

# flush
$fh->close; 

# xmakemol
xmakemol($output, $quiet); 
