#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use Storable qw(dclone);

use MD qw( read_profile retrieve_traj is_valid_istep sort_profile moving_average print_trajectory ); 
use VASP qw( read_poscar print_poscar ); 
use XYZ qw( set_pbc tag_xyz direct_to_cart xmakemol );   

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 

mdanalyze.pl: MD analysis

=head1 SYNOPSIS

mdanalyze.pl [-h] [-p] <profile> [-t] <trajectory> -s -d 0 0 0.5 -q

=head1 OPTIONS  

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-r> 

reference file (default: POSCAR)

=item B<-p> 

Potential energy file  (default: profile.dat)

=item B<-t> 

Trajectory file (default: traj.dat)

=item B<-a> 

Calculate moving average from md profile

=item B<-e> 

Extract mode (POSCAR and config-#.xyz)

=item B<-m> 

Movie mode (movie.xyz)

=item B<-s> 

Sort mode (minima/maxima/pes.xyz)

=item B<-n> 

Period of average/movie snapshot/sort

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default: none)

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=back

=cut

# default optional arguments
my $help       = 0; 
my $reference  = 'POSCAR'; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 
my $average    = 0; 
my $movie      = 0; 
my $extract    = 0; 
my $sort       = 0; 
my $period     = 100; 
my @dxyz       = ();  
my @nxyz       = ();  
my $quiet      = 0; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'r=s'    => \$reference, 
    'p=s'    => \$profile, 
    't=s'    => \$trajectory, 
    'a'      => \$average, 
    'e=i'    => \$extract, 
    'm'      => \$movie, 
    's'      => \$sort, 
    'n=i'    => \$period, 
    'q'      => \$quiet, 
    'd=f{3}' => \@dxyz,  
    'c'      => sub { @dxyz = ( 0.5,0.5,0.5 ) },  
    'x=i{3}' => sub { push @nxyz, [0..$_[1]-1] },  
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# read cell infon from reference file (POSCAR/CONTCAR)
my %reference = read_poscar($reference); 

# tag
my @tags = tag_xyz($reference{atom}, $reference{natom}, \@nxyz); 

# ISTEP, T, F from profile.dat 
my %profile = read_profile($profile); 

# geometry from trajectory
my %traj = retrieve_traj($trajectory); 

# pbc box 
@nxyz = ( @nxyz == 0 ? ([0], [0], [0]) : @nxyz );  

# analysis
my @analysis = (); 

# moving average 
$average && do { 
    my $output = 'averages.dat'; 
    moving_average(\%profile, $period => $output); 
}; 

# extract istep from trajectory 
$extract && do { 
    my ( $poscar, $xyz ) = ( "POSCAR.#$extract", "step-#$extract.xyz"); 

    # sanity check 
    is_valid_istep($extract, \%profile, \%traj); 
    print "=> Extracting $poscar, $xyz\n"; 

    # POSCAR.#
    $reference{geometry} = $traj{$extract}; 
    print_poscar(\%reference => $poscar );  

    push @analysis, [[$extract], $xyz,$quiet];  
}; 

# md snapshot
$movie && do { 
    my $xyz = 'movie.xyz'; 
    print "=> Snapshot with period of $period ionic steps: movie.xyz\n";  

    # extraction every $periodicity of ionic steps 
    my @snapshots = grep { $_ % $period == 1 } ( sort {$a <=> $b} keys %traj ); 

    push @analysis, [\@snapshots, $xyz, $quiet];  
}; 

# md sort 
$sort && do { 
    my ( @minima, @maxima, @pes ) = (); 
    my ( $minima, $maxima, $pes ) = ( 'minima.xyz', 'maxima.xyz', 'pes.xyz' ); 
    print "=> Potential energy surface: $minima, $maxima, $pes\n";  

    # sort md profile 
    sort_profile(\%profile, $period => \@minima, \@maxima, \@pes); 

    push @analysis, ( [\@minima, $minima, 1], [\@maxima, $maxima, 1], [\@pes, $pes, 1] );   
}; 

# print xyz files
for ( @analysis ) { 
    my ( $step, $xyz, $quiet ) = @$_; 
    print_trajectory($step, \%profile, \%traj, \%reference, \@dxyz, \@nxyz => $xyz);  
    xmakemol($quiet, $xyz); 
}
