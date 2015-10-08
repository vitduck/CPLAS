#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use IO::File; 
use List::Util qw(sum);  
use Pod::Usage; 

use GenUtil qw( read_line ); 
use Math    qw ( elem_product dot_product); 
use VASP    qw( read_cell read_geometry print_poscar ); 
use XYZ     qw ( cart_to_direct direct_to_cart print_comment xmakemol );

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 


# POD 
=head1 NAME 
frozen.pl: let it go!

=head1 SYNOPSIS

frozen.pl [-h] [-i] <POSCAR> [-f] <atomic order> [-c]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

input file (default: POSCAR)

=item B<-f> 

List of unfrozen atoms

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
my $quiet = 0; 
my @nxyz  = (1, 1, 1); 
my @dxyz  = (1.0,1.0,1.0); 
my @free  = (); 

# input & output
my $input = 'POSCAR'; 
my $xyz   = 'frozen.xyz'; 

# parse optional arguments 
GetOptions(
    'h'       => \$help, 
    'i=s'     => \$input, 
    'f=i{1,}' => \@free, 
    'c'       => sub { 
        @dxyz = (0.5,0.5,0.5) 
    },  
    'd=f{3}'  => sub { 
        my ($opt, $arg) = @_; 
        shift @dxyz; 
        push @dxyz, $arg;  
    }, 
    'q'       => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help or @free == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# read POSCAR 
my $line = read_line($input); 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 
my $geometry = read_geometry($line); 

# supercell box
my ($nx, $ny, $nz) = map [0..$_-1], @nxyz; 

# total number of atom in supercell 
$natom = dot_product(elem_product(\@nxyz), $natom); 
my $ntotal = sum(@$natom);  
my $label  = [map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom];  

# frozen 
my $count = 0; 
for my $atom ( @$geometry ) { 
    $count++; 
    if ( grep $_ eq $count, @free ) { 
        @$atom[3..5] = qw( T T T ); 
    } else { 
        @$atom[3..5] = qw( F F F ); 
    }
}

print_poscar(*STDOUT, $title, $scaling, $lat, $atom, $natom, "Selective Dynamics", $type, $geometry); 
