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
my %md = read_md($profile); 

# xyz from trajectory
my %xyz = retrieve_xyz($trajectory);  

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
my $fh1 = IO::File->new($output1, 'w') or die "Cannot write to $output1\n"; 
my $fh2 = IO::File->new($output2, 'w') or die "Cannot write to $output2\n"; 

for my $index (0..$#$local_minima) { 
    my $minxyz = $xyz{$local_minima->[$index]}; 
    my $maxxyz = $xyz{$local_maxima->[$index]}; 
    
    # print coordinate to minima.xyz
    print_header($fh1, $minxyz, $local_minima->[$index], \%md); 
    for my $atom (@$minxyz) { 
        print_coordinate($fh1, @$atom); 
    }

    # print coordinate to maxima.xyz
    print_header($fh2, $maxxyz, $local_maxima->[$index], \%md); 
    for my $atom (@$maxxyz) { 
        print_coordinate($fh2, @$atom); 
    }
}

# flush
$fh1->close; 
$fh2->close; 

# => pes .xyz
my $fh3 = IO::File->new($output3, 'w') or die "Cannot write to $output3\n"; 
for my $istep ( @pes ) { 
    my $xyz = $xyz{$istep}; 
    
    # print coordinate to pes.xyz
    print_header($fh3, $xyz, $istep, \%md); 
    
    for my $atom (@$xyz) { 
        print_coordinate($fh3, @$atom); 
    }
}

# flush
$fh3->close; 
