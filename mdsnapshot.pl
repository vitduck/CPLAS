#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use IO::File; 
use List::Util qw( sum ); 

use GenUtil qw( read_line print_table ); 
use VASP    qw( read_cell read_md retrieve_traj ); 
use XYZ     qw( print_header direct_to_cart xmakemol); 
use Math    qw( elem_product dot_product ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdsnapshot.pl: take snapshot every period of inonic step 

=head1 SYNOPSIS

mdsnapshot.pl [-h] [-p] <profile> [-t] <trajectory> [-c] [-q] [-n 100]

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

=item B<-n>

period of ionic step for taking snapshot

=back

=cut

# default optional arguments 
my $help       = 0; 
my $quiet      = 0; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 
my $output     = 'movie.xyz'; 
my @nxyz       = (1,1,1); 
my @dxyz       = (1.0,1.0,1.0); 
my $period     = 100; 
 
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
    'n=i' => \$period
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }


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


# ISTEP, T, F from profile.dat 
my %md = read_md($profile); 

# geometry from trajectory
my %traj = retrieve_traj($trajectory); 

# extraction every $periodicity of ionic steps 
my @snapshots = grep { $_ % $period == 1  } (sort {$a <=> $b} keys %traj); 

print "=> Snapshot with period of $period ionic steps: $output\n"; 

# movie.xyz
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  

print_table(\@snapshots); 

for my $istep (@snapshots) { 
    print_header($fh, "%d\n#%d:  T= %.1f  F= %-10.5f\n", $ntotal, $istep, @{$md{$istep}}); 
    direct_to_cart($fh, $scaling, $lat, $label, $traj{$istep}, \@dxyz, $nx, $ny, $nz); 
}

# flush
$fh->close; 

# xmakemol
xmakemol($output, $quiet);
