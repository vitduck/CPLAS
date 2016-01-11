#!/usr/bin/perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use Math::Linalg qw( sum ); 
use VASP qw( read_poscar print_poscar ); 
use XYZ  qw( cartesian_to_direct direct_to_cartesian print_cartesian set_pbc tag_xyz xmakemol );  

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

frozen.pl: by Elsa

=head1 SYNOPSIS

frozen.pl [-h] [-i] <POSCAR> [-d dx dy dz] [-l 1 2 5 8] [-f x y z] [-q] 

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

=item B<-l> 

List of atom to be frozen

=item B<-f> 

Component to be fixed (default: x y z)

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments
my $help   = 0; 
my $input  = 'POSCAR'; 
my $quiet  = 0; 
my @dxyz   = ();  
my @list   = (); 
my @frozen = ();  

my $poscar = 'POSCAR.frozen'; 
my $xyz    = 'frozen.xyz'; 

# corresponding indices 
my %frozen = ( 
    x => 0, 
    y => 1, 
    z => 2, 
); 

# parse optional arguments 
GetOptions(
    'h'       => \$help, 
    'i=s'     => \$input, 
    'q'       => \$quiet, 
    'd=f{3}'  => \@dxyz,  
    'l=i{1,}' => \@list, 
    'f=s{1,}' => \@frozen, 
    'c'       => sub { @dxyz = (0.5,0.5,0.5) },  
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# read POSCAR 
my %poscar = read_poscar($input); 

# transform into  hash for easy indexing 
my $natom = sum(@{$poscar{natom}}); 
my %geometry = map { $_+1 => $poscar{frozen}[$_] } 0..$natom-1; 

# default frozen list 
@frozen = ( @frozen == 0 ? qw( x y z ) : @frozen );  

# let it go ! let it go !
for my $atom ( @list ) { 
    # sanity check 
    if ( ! exists $geometry{$atom} ) { next } 
    
    map { $geometry{$atom}[$frozen{$_}] = 'F' } @frozen; 
}

# write frozen poscar 
$poscar{selective} = 1; 
print_poscar(\%poscar => $poscar); 

# pbc box 
my @nxyz = ([0], [0], [0]); 

# convert to direct coordinate + pbc shift
if ( $poscar{type} =~ /^\s*[ck]/i ) { 
    @{$poscar{geometry}} = cartesian_to_direct($poscar{cell}, $poscar{geometry}); 
}

# tag  
my @tags = tag_xyz($poscar{atom}, $poscar{natom}, \@nxyz, 'frozen', $poscar{frozen} ); 

# print coordinate to poscar.xyz
open my $fh, '>', $xyz or die "Cannot write to $xyz\n"; 
my @xyz = direct_to_cartesian($poscar{cell}, $poscar{geometry}, \@dxyz, \@nxyz); 
print_cartesian($poscar{name}, \@tags, \@xyz => $fh); 
close $fh; 

# xmakemol
if ( $quiet == 0 ) { xmakemol($xyz) } 
