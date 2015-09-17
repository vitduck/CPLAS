#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use GenUtil  qw ( read_line ); 
use VASP     qw ( read_cell read_geometry ); 
use XYZ      qw ( make_box make_label make_xyz xmakemol ); 

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
my $help   = 0; 
my $center = 0; 
my $quiet  = 0; 
my @nxyz   = (1,1,1); 

# input & output
my $input  = 'CONTCAR'; 
my $output = 'contcar.xyz'; 

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

# CONTCAR lines
my $line = read_line($input); 

# cell parameters 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 

# atomic positions 
my $coordinate = read_geometry($line); 

# supercell box
my ($nx, $ny, $nz, $ntotal) = make_box($natom, @nxyz); 

# xyz label 
my $label = make_label($atom, $natom, @nxyz); 

# contcar.xyz
my $fh = IO::File->new($output, 'w'); 

printf $fh "%d\n\n", $ntotal; 
my @xyz = make_xyz($fh, $scaling, $lat, $label, $type, $coordinate, $center, $nx, $ny, $nz); 

# flush
$fh->close;  

# xmakemol
xmakemol($output, $quiet); 
