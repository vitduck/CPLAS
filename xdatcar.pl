#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use IO::File; 
use List::Util qw(sum);  
use Pod::Usage; 

use GenUtil qw( read_line ); 
use Math    qw( elem_product dot_product );   
use VASP    qw( read_cell read_traj save_traj );  
use XYZ     qw( print_comment direct_to_cart xmakemol ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
xdatcar.pl: convert XDATCAR to ion.xyz

=head1 SYNOPSIS

xdatcar.pl [-h] [-i] <POSCAR> [-c] [-d dx dy dz] [-x nx ny nz] [-s] [-q] 

=head1 OPTIONS

=over 8 

=item B<-h>

Print the help message and exits.

=item B<-i> 

Input file (default: XDATCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-s> 

Save trajectory to disk in quiet mode (default: no) 

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments 
my $help   = 0; 
my $quiet  = 0; 
my $save   = 0; 
my @nxyz   = (1,1,1); 
my @dxyz   = (1.0,1.0,1.0); 

# input & output
my $xdatcar = 'XDATCAR'; 
my $xyz     = 'ion.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$xdatcar,
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
    's'      => \$save, 
    'q'      => \$quiet
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# XDATCAR lines
my $line = read_line($xdatcar, 'slurp'); 
my ($title, $scaling, $lat, $atom, $natom, $traj) = read_traj($line); 

# supercell box
my ($nx, $ny, $nz) = map [0..$_-1], @nxyz; 

# total number of atom in supercell 
$natom = dot_product(elem_product(\@nxyz), $natom); 
my $ntotal = sum(@$natom);  
my $label  = [map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom];  

# save direct coordinate to hash for lookup
my $count = 0;  
my %traj  = (); 

# write to xdatcar.xyz
my $fh = IO::File->new($xyz, 'w') or die "Cannot write to $xyz\n"; 
for ( @$traj ) { 
    $count++; 
    my $geometry = [ map [ split  ], split /\n/ ]; 
    $traj{$count} = $geometry; 
    print_comment($fh, "%d\n# Step: %d\n", $ntotal, $count); 
    direct_to_cart($fh, $scaling, $lat, $label, $geometry, \@dxyz, $nx, $ny, $nz); 
}

## flush
$fh->close; 

# store trajectory
$save ? save_traj(\%traj, 'traj.dat', $save) : xmakemol($xyz, $quiet); 
