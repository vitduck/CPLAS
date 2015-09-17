#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( read_line ); 
use VASP    qw( read_cell read_traj );  
use XYZ     qw( make_box make_label make_xyz save_xyz xmakemol ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

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
my $help        = 0; 
my $centralized = 0; 
my $quiet       = 0; 
my $save        = 0; 
my @nxyz        = (1,1,1); 

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
    'x=i{3}' => sub { 
        my ($opt, $arg) = @_; 
        shift @nxyz; 
        push @nxyz, $arg; 
    }
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# XDATCAR lines
my $line = read_line($input); 

# cell parameters 
my ($scaling, $lat, $atom, $natom, $type) = read_cell($line); 

# read ionic trajectories
my @trajs = read_traj($line); 

# supercell box
my ($nx, $ny, $nz, $ntotal) = make_box($natom, @nxyz); 

# xyz label 
my $label = make_label($atom, $natom, @nxyz); 

# xdatcar.xyz
my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n"; 

# loop of all ionic steps
my $count = 0;  
my %traj  = (); 
for my $traj ( @trajs ) { 
    $count++; 
    printf $fh "%d\n# Step: %d\n", $ntotal, $count; 
    my @xyz = make_xyz($fh, $scaling, $lat, $label, $type, $traj, $centralized, $nx, $ny, $nz); 
    $traj{$count} = [@xyz]; 
}

# flush
$fh->close; 

# store trajectory
$save ? save_xyz(\%traj, 'traj.dat', $save) : xmakemol($output, $quiet); 
