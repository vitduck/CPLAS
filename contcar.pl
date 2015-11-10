#!/usr/bin/perl 

use strict; 
use warnings; 

use Data::Dumper; 
use Getopt::Long; 
use IO::File; 
use Pod::Usage; 

use VASP qw/read_poscar/;  
use XYZ  qw/info_xyz cart_to_direct direct_to_cart set_pbc xmakemol/; 

my @usages = qw/NAME SYSNOPSIS OPTIONS/;  

# POD 
=head1 NAME 
contcar.pl: convert CONTCAR to contcar.xyz

=head1 SYNOPSIS

contcar.pl [-h] [-i] <CONTCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-q] 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: CONTCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting 

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments
my $help   = 0; 
my $quiet  = 0; 

my @nxyz   = ( );  
my @dxyz   = ( );  

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
        push @dxyz, $arg;  
    }, 
    'x=i{3}' => sub { 
        my ($opt, $arg) = @_; 
        push @nxyz, $arg; 
    }, 
    'q'      => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# read CONTCAR
my ( $title, $scaling, $lat, $atom, $natom, $dynamics, $type, $geometry ) = read_poscar($input); 

# supercell box
my ($nx, $ny, $nz) = @nxyz ? @nxyz : (1,1,1);  

# total number of atom in supercell 
my ( $ntotal, $label ) = info_xyz($atom, $natom, $nx, $ny, $nz);  

#write poscar.xyz
my $fh = IO::File->new($xyz, 'w') or die "Cannot write to $xyz\n";  

# total number of atom 
printf $fh "%d\n\n", $ntotal; 

# convert to direct coordinate + pbc shift
my @direct = ( $type =~ /^\s*c/i ) ? cart_to_direct($lat, $geometry) : @$geometry;  

# PBC
if ( @dxyz ) { set_pbc(\@direct, @dxyz) } 

# print coordinate to contcar.xyz
direct_to_cart($fh, $scaling, $lat, $label, \@direct, $nx, $ny, $nz); 

$fh->close; 

# xmakemol
xmakemol($xyz, $quiet); 
