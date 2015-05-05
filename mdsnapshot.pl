#!/usr/bin/env perl 

use strict; 
use warnings; 

use Vasp qw(get_line get_potential_file retrieve_xyz print_header print_coordinate); 
use Getopt::Long qw(:config bundling);  
use Pod::Usage; 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 

mdsnapshot.pl: take snapshot every period of inonic step 

=head1 SYNOPSIS

mdsnapshot.pl [-h] [-p] <potential file> [-t] <trajectory file> [-n 100]

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
my $output     = 'movie.dat'; 
my $period     = 100; 
 
# parse optional arguments 
GetOptions( 
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
    'n=i' => \$period
) or pod2usage(-verbose => 99, -section => \@usages); 

# help message
pod2usage(-verbose => 99, -section => \@usages) if $help; 

# ISTEP, T, F from profile.dat 
my %md = get_potential_file($profile); 

# geometry from trajectory
my $r2xyz = retrieve_xyz($trajectory); 

# extraction every $periodicity of ionic steps 
my @snapshots = grep { $_ % $period == 1  } (sort {$a <=> $b} keys %$r2xyz); 

print "=> Snapshot with period of $period ionic steps: $output\n"; 

# movie.xyz
open my $fh, '>', $output or die "Cannot write to $output\n"; 

# split snapshots into bath of 5
while ( my @frames = splice @snapshots, 0, 5 ) { 
    print "@frames\n"; 
    # loop of frame subset
    for my $istep (@frames) { 
        # coordinate from hash table 
        my $coordinate = $r2xyz->{$istep}; 
        print_header($fh, $coordinate, $istep, \%md); 
        for my $atom ( @$coordinate ) { 
            print_coordinate($fh, @$atom); 
        }        
    }
}

# flush
close $fh; 
