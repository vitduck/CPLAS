#!/usr/bin/perl 

use strict; 
use warnings; 

use Getopt::Long; 
use IO::File; 
use List::Util qw(sum);  
use Pod::Usage; 

use GenUtil qw ( read_line ); 
use Math    qw ( elem_product dot_product);   
use VASP    qw ( read_cell read_geometry ); 
use XYZ     qw ( direct_to_cart print_comment xmakemol );

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
contcar.pl: convert POSCAR to poscar.xyz

=head1 SYNOPSIS

contcar.pl [-h] [-i] <POSCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-q] 

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
my $quiet  = 0; 
my @nxyz   = (1,1,1); 
my @dxyz   = (1.0,1.0,1.0); 

# input & output
my $input  = 'CONTCAR'; 
my $xyz    = 'contcar.xyz'; 

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

# read CONTCAR
my $line = read_line($input); 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 
my $geometry = read_geometry($line); 

# supercell box
my ($nx, $ny, $nz) = map [0..$_-1], @nxyz; 

# total number of atom in supercell 
$natom = dot_product(elem_product(\@nxyz), $natom); 
my $ntotal = sum(@$natom);  
my $label  = [map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom];  

# write contcar.xyz
my $fh = IO::File->new($xyz, 'w') or die "Cannot write to $xyz\n";  
print_comment($fh, "%d\n%s\n", $ntotal, ''); 
direct_to_cart($fh, $scaling, $lat, $label, $geometry, \@dxyz, $nx, $ny, $nz); 
$fh->close; 

# xmakemol
xmakemol($xyz, $quiet); 
