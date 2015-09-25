#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use List::Util qw( sum ); 
use Pod::Usage; 

use GenUtil qw( read_line print_table ); 
use Math    qw( elem_product dot_product ); 
use VASP    qw( read_cell read_md sort_md retrieve_traj ); 
use XYZ     qw( print_comment direct_to_cart xmakemol ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdsort.pl: find local minima/maxima within periods of ionic step 

=head1 SYNOPSIS

mdsort.pl [-h] [-p] <profile> [-t] <trajectory> [-n 1000] [-c] [-q]

=head1 OPTIONS

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-p> 

Potential energy file  (default: profile.dat)

=item B<-t> 

Trajectory file (default: traj.dat)

=item B<-n>

Number of ion steps for minima/maxima search (default: 1000)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-d> 

PBC shifting (default [1.0, 1.0. 1.0])

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=back

=cut

# default optional arguments
my $help       = 0; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 
my $period     = 1000; 
my @nxyz       = (1,1,1); 
my @dxyz       = (1.0,1.0,1.0); 

my $output1    = 'minima.xyz'; 
my $output2    = 'maxima.xyz'; 
my $output3    = 'pes.xyz'; 

# parse optional arguments 
GetOptions(
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
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
        push @nxyz, $arg-1; 
    }, 
    'n=i' => \$period, 
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

# xyz from trajectory
my %traj = retrieve_traj($trajectory);  

# sort 
my ($local_minima, $local_maxima) = sort_md(\%md, $period); 
my @pes = sort { $a <=> $b } (@$local_minima, @$local_maxima); 

# local minima/maxima
print "=> Local minimum with period of $period steps:\n"; 
print_table($local_minima); 

print "\n"; 

print "=> Local maxima with period of $period steps:\n"; 
print_table($local_maxima); 

# weired situation ? 
unless ( @$local_minima == @$local_maxima ) { die "Something weired is going on\n" }

# remove minima, maxima files 
unlink ($output1, $output2, $output3); 
unlink < minimum-* >; 

# minima.xyz, maxima.xyz
my $fh1 = IO::File->new($output1, 'w') or die "Cannot write to $output1\n"; 
my $fh2 = IO::File->new($output2, 'w') or die "Cannot write to $output2\n"; 

for my $index (0..$#$local_minima) { 
    my $minxyz = $traj{$local_minima->[$index]}; 
    my $maxxyz = $traj{$local_maxima->[$index]}; 
    
    # print coordinate to minima.xyz
    print_comment($fh1, "%d\n#%d:  T= %.1f  F= %-10.5f\n", $ntotal, $local_minima->[$index], @{$md{$local_minima->[$index]}}); 
    direct_to_cart($fh1, $scaling, $lat, $label, $minxyz, \@dxyz, $nx, $ny, $nz); 
    
    # print coordinate to maxima.xyz
    print_comment($fh2, "%d\n#%d:  T= %.1f  F= %-10.5f\n", $ntotal, $local_maxima->[$index], @{$md{$local_maxima->[$index]}}); 
    direct_to_cart($fh2, $scaling, $lat, $label, $maxxyz, \@dxyz, $nx, $ny, $nz); 
}

# flush
$fh1->close; 
$fh2->close; 

# => pes .xyz
my $fh3 = IO::File->new($output3, 'w') or die "Cannot write to $output3\n"; 
for my $index ( @pes ) { 
    my $geometry = $traj{$index}; 
    print_comment($fh3, "%d\n#%d:  T= %.1f  F= %-10.5f\n", $ntotal, $index, @{$md{$index}}); 
    direct_to_cart($fh3, $scaling, $lat, $label, $geometry, \@dxyz, $nx, $ny, $nz); 
}

# flush
$fh3->close; 
