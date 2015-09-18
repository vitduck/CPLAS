#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use IO::File; 
use List::Util qw( sum );  

use GenUtil qw( read_line ); 
use VASP    qw( read_cell read_geometry read_md retrieve_traj ); 
use XYZ     qw( print_header print_xyz xmakemol); 
use Math    qw ( elem_product dot_product);   

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdextract.pl: extract specific geometries along MD trajectry 

=head1 SYNOPSIS

mdextract.pl [-h] [-p] <profile> [-t] <trajectory> [-c] ionic_step 

=head1 OPTIONS  

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-p> 

Potential energy file  (default: profile.dat)

=item B<-t> 

Trajectory file (default: traj.dat)

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
my $help       = 0; 
my $quiet      = 0; 
my @nxyz       = (1,1,1); 
my @dxyz       = (1.0,1.0,1.0); 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 

# parse optional arguments 
GetOptions( 
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
    'c'   => sub { 
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
    'q' => \$quiet, 
) or pod2usage(-verbose => 1); 

# help message
if ( $help or @ARGV == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# POSCAR/CONTCAR 
my ($ref) = grep -e $_, qw( POSCAR CONTCAR ); 
unless ( $ref ) { die "POSCAR/CONTCAR is required for cell parameters\n" } 

# read POSCAR/CONTCAR 
my $line = read_line($ref); 
my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type) = read_cell($line); 

# supercell box
my ($nx, $ny, $nz) = map [0..$_-1], @nxyz; 

# total number of atom in supercell 
$natom = dot_product(elem_product(\@nxyz), $natom); 
my $ntotal = sum(@$natom);  
my $label  = [map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom];  

# extract geometry from @ARGV 
my $config = shift @ARGV;  
my $output = "$config.xyz"; 

# ISTEP, T, F from profile.dat 
my %md = read_md($profile); 

# geometry from trajectory
my %traj = retrieve_traj($trajectory); 

# sanity check
unless ( exists $md{$config} )   { die "=> $output does not exist in MD profile\n" } 
unless ( exists $traj{$config} ) { die "=> $output does not exist in MD trajectory\n" } 

# write xyz file  
print "=> Extracting $output\n";  
    
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  
print_header($fh, "%d\n#%d:  T= %.1f  F= %-10.5f\n", $ntotal, $config, @{$md{$config}}); 
print_xyz($fh, $scaling, $lat, $label, $traj{$config}, \@dxyz, $nx, $ny, $nz); 
$fh->close; 

# xmakemol
xmakemol($output, $quiet); 
