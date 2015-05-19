#!/usr/bin/env perl 

use strict; 
use warnings; 

use Vasp qw(save_xyz retrieve_xyz get_potential_file); 
use Getopt::Long; 
use Pod::Usage; 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 

mdmerge.pl: merge multiple trajectories and potential profiles 

=head1 SYNOPSIS

mdmerge.pl [-h] [-p] <potential file> [-t] <trajectory files> 

=head1 OPTIONS  

=over 8 

=item B<-h>

Print the help message and exit.

=item B<-p> 

List of potential energy files to be merged 

=item B<-t> 

List of trajectory  files to be merged 

=back

=cut 

# default optional arguments 
my $help = 0; 
my (@trajectories, @profiles); 

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 99, -section => \@usages) }

# parse optional arguments 
GetOptions(
    'h'       => \$help, 
    't=s{1,}' => \@trajectories, 
    'p=s{1,}' => \@profiles
) or pod2usage(-verbose => 99, -section => \@usages);

# help message 
pod2usage(-verbose => 99, -section => \@usages) if $help; 

# profile files
if (@profiles) { 
    print "Merging profiles as:  "; 
    chomp (my $output = <STDIN>); 

    open OUTPUT, '>'. $output or die "Cannot write to $output\n"; 
    print OUTPUT "# global local T(K) Potental(eV)\n";

    # all profile.dat; 
    my $count = 0; 
    for my $profile (@profiles) { 
        printf OUTPUT "# $profile\n"; 
        
        # potential from file 
        my %md = get_potential_file($profile);     
        
        # re-write with accumulated ionic step 
        for my $istep ( sort { $a <=> $b } keys %md ) { 
            printf OUTPUT "%d\t%d\t%5d\t%10.5f\n", ++$count, $istep, @{$md{$istep}};  
        }

        # record break 
        print OUTPUT "\n\n" unless $profile eq $profiles[-1];  
    }

    # flush
    close OUTPUT; 
}

# trajectory files 
if (@trajectories) { 
    my %xyz; 
    print "Merging trajectories as:  "; 
    chomp (my $output = <STDIN>); 
    for my $traj ( @trajectories ) { 
        # hash size
        my $size = keys %xyz; 

        # trajectory from previous MD 
        my $r2xyz  = retrieve_xyz($traj); 
        my @keys   = keys  (%$r2xyz); 

        # shift of hash key 
        @keys = map { $_ + $size } @keys; 
        
        # new hash 
        @xyz{@keys} = values(%$r2xyz);
            }
    # store joined hash to output 
    save_xyz(\%xyz, $output, 1); 
}
