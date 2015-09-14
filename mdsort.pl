#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( print_table ); 
use VASP    qw( read_md sort_md ); 
use XYZ     qw( retrieve_xyz print_header print_coordinate ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdsort.pl: find local minima/maxima within periods of ionic step 

=head1 SYNOPSIS

mdsort.pl [-h] [-p] <profile> [-t] <trajectory> [-n 1000]

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

=back

=cut

# default optional arguments
my $help       = 0; 
my $profile    = 'profile.dat'; 
my $trajectory = 'traj.dat'; 
my $output1    = 'minima.xyz'; 
my $output2    = 'maxima.xyz'; 
my $output3    = 'pes.xyz'; 
my $period     = 1000; 

# parse optional arguments 
GetOptions(
    'h'   => \$help, 
    'p=s' => \$profile, 
    't=s' => \$trajectory, 
    'n=i' => \$period, 
) or pod2usage(-verbose => 1); 

# help message
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) } 

# ISTEP, T, F from profile.dat
my %md; 
eval { %md = read_md($profile) };  
if ( $@ ) { pod2usage(-verbose => 1, -message => $@) }; 

# xyz from trajectory
my $r2xyz; 
eval { $r2xyz = retrieve_xyz($trajectory) };  
if ( $@ ) { pod2usage(-verbose => 1, -message => $@) }; 

# sort 
my ($local_minima, $local_maxima) = sort_md(\%md, $period); 
my @pes = sort { $a <=> $b } (@$local_minima, @$local_maxima); 

# local minima/maxima
print "=> Local minimum with period of $period steps:\n"; 
print_table(@$local_minima); 

print "\n"; 

print "=> Local maxima with period of $period steps:\n"; 
print_table(@$local_maxima); 

# weired situation ? 
unless ( @$local_minima == @$local_maxima ) { die "Something weired is going on\n" }

# remove minima, maxima files 
unlink ($output1, $output2, $output3); 
unlink < minimum-* >; 

# minima.xyz, maxima.xyz
open my $min, '>', $output1 or die "Cannot write to $output1\n";  
open my $max, '>', $output2 or die "Cannot write to $output2\n";  

for my $index (0..$#$local_minima) { 
    my $minxyz = $r2xyz->{$local_minima->[$index]}; 
    my $maxxyz = $r2xyz->{$local_maxima->[$index]}; 
    
    # print coordinate to minima.xyz
    print_header($min, $minxyz, $local_minima->[$index], \%md); 
    for my $atom (@$minxyz) { 
        print_coordinate($min, @$atom); 
    }
    # print coordinate to maxima.xyz
    print_header($max, $maxxyz, $local_maxima->[$index], \%md); 
    for my $atom (@$maxxyz) { 
        print_coordinate($max, @$atom); 
    }
}

# flush
close $min; 
close $max; 

# => pes .xyz
open my $pes, '>', $output3 or die "Cannot write to $output3\n";  
for my $istep ( @pes ) { 
    my $xyz = $r2xyz->{$istep}; 
    
    # print coordinate to pes.xyz
    print_header($pes, $xyz, $istep, \%md); 
    
    for my $atom (@$xyz) { 
        print_coordinate($pes, @$atom); 
    }
}

# flush
close $pes; 
