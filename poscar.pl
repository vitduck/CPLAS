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

poscar.pl [-h] [-i] <POSCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-q] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: POSCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help   = 0; 
my $center = 0; 
my $quiet  = 0; 
my @nxyz   = (1,1,1); 
my @dxyz   = (1.0,1.0,1.0); 

# input & output
my $input  = 'POSCAR'; 
my $output = 'poscar.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input, 
    'c'      => sub { 
        @dxyz = (0.5,0.5,0.5) 
    },  
    'd=f{3}' => sub { 
        my ($opt, $arg) = @_; 
        shift @dxyz; 
        push @dxyz, $arg;  
    }, 
    'x=i{3}' => sub { 
        my ($opt, $arg) = @_; 
        shift @nxyz; 
        push @nxyz, $arg; 
    }, 
    'q'      => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# POSCAR lines
my $line = read_line($input); 

# cell parameters 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 

# atomic positions 
my $coordinate = read_geometry($line); 

# supercell box
my ($nx, $ny, $nz, $ntotal) = make_box($natom, @nxyz); 

# xyz label 
my $label = make_label($atom, $natom, @nxyz); 

# poscar.xyz
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  

printf $fh "%d\n\n", $ntotal; 
my @xyz = make_xyz($fh, $scaling, $lat, $label, $type, $coordinate, \@dxyz, $nx, $ny, $nz); 

# flush
$fh->close; 

# xmakemol
xmakemol($output, $quiet); 
