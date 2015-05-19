#!/usr/bin/env perl 

use strict; 
use warnings; 

use Vasp qw(get_line get_cell get_traj :xyz :store); 
use Getopt::Long; 
use Pod::Usage; 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
 xdatcar.pl: convert XDATCAR to ion.xyz

=head1 SYNOPSIS

xdatcar.pl [-h] [-c] [-q] [-s] [-x nx ny nz]

=head1 OPTIONS

=over 8 

=item B<-h>

Print the help message and exits.

=item B<-i> 

Input file (default: XDATCAR)

=item B<-c> 

Centralize the coordinate (default: no) 

=item B<-q> 

Quiet mode, i.e. do not launch xmakemol (default: no) 

=item B<-s> 

Save trajectory to disk in quiet mode (default: no) 

=item B<-x> 

Generate nx x ny x nz supercell (default: 1 1 1)

=back

=cut

# default optional arguments 
my @nxyz        = (); 
my $help        = 0; 
my $centralized = 0; 
my $quiet       = 0; 
my $save        = 0; 

# input & output
my $input  = 'XDATCAR'; 
my $output = 'ion.xyz'; 

# parse optional arguments 
GetOptions(
    'h'      => \$help, 
    'i=s'    => \$input,
    'c'      => \$centralized, 
    's'      => \$save, 
    'q'      => \$quiet, 
    'x=i{3}' => \@nxyz
) or pod2useage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# XDATCAR lines
my @lines = get_line($input); 

# cell parameters 
my ($scaling, $r2lat, $r2atom, $r2natom, $type) = get_cell(\@lines); 

# read atomic positions 
my @trajs = get_traj(\@lines); 

# default supercell expansion 
unless ( @nxyz == 3 ) { @nxyz = (1, 1, 1) }

# scalar to array ref 
my ($nx, $ny, $nz) = map { [0..$_-1] } @nxyz; 

# supercell parameters
my ($label, $natom, $ntotal) = make_cell($r2atom, $r2natom, $nx, $ny, $nz); 

# xdatcar.xyz
open my $fh, '>', $output; 

# loop of all ionic steps
my $count = 0;  
my %traj  = (); 
for my $traj ( @trajs ) { 
    $count++; 
    printf $fh "%d\n#%d\n", $ntotal, $count; 
    my @xyz = make_xyz($fh, $scaling, $r2lat, $label, $type, $traj, $centralized, $nx, $ny, $nz); 
    $traj{$count} = [@xyz]; 
}

# flush
close $fh; 

# store trajectory
if ( $save ) { 
    save_xyz(\%traj, 'traj.dat', $save);  
} else { 
    view_xyz($output, $quiet); 
}
