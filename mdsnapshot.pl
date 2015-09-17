#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( print_table ); 
use VASP    qw( read_md ); 
use XYZ     qw( retrieve_xyz print_header print_coordinate ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdsnapshot.pl: take snapshot every period of inonic step 

=head1 SYNOPSIS

mdsnapshot.pl [-h] [-p] <profile> [-t] <trajectory> [-n 100]

=head1 OPTIONS  

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-p> 

Potential energy file  (default: profile.dat)

=item B<-t> 

Trajectory file (default: traj.dat)

=item B<-n>

period of ionic step for taking snapshot

=back

=cut

# default optional arguments 
my $help       = 0; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 
my $output     = 'movie.xyz'; 
my $period     = 100; 
 
# parse optional arguments 
GetOptions( 
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
    'n=i' => \$period
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# ISTEP, T, F from profile.dat 
my %md = read_md($profile); 

# geometry from trajectory
my %xyz = retrieve_xyz($trajectory); 

# extraction every $periodicity of ionic steps 
my @snapshots = grep { $_ % $period == 1  } (sort {$a <=> $b} keys %xyz); 

print "=> Snapshot with period of $period ionic steps: $output\n"; 

# movie.xyz
open my $fh, '>', $output or die "Cannot write to $output\n"; 

print_table(\@snapshots); 
# split snapshots into bath of 5
for my $istep (@snapshots) { 
    # coordinate from hash table 
    my $coordinate = $xyz{$istep}; 
    print_header($fh, $coordinate, $istep, \%md); 
    for my $atom ( @$coordinate ) { 
        print_coordinate($fh, @$atom); 
    }        
}

# flush
close $fh; 
