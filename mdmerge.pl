#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use VASP qw( read_md ); 
use XYZ  qw( save_xyz retrieve_xyz ); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 

mdmerge.pl: merge multiple trajectories and potential profiles 

=head1 SYNOPSIS

mdmerge.pl [-h] [-p] <profiles> [-t] <trajectories> 

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
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }; 

# parse optional arguments 
GetOptions(
    'h'       => \$help, 
    't=s{1,}' => \@trajectories, 
    'p=s{1,}' => \@profiles
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# profile files
if (@profiles) { 
    print "Merging profiles as:  "; 
    chomp (my $output = <STDIN>); 
    print "\n"; 

    my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n"; 

    print $fh "# global local T(K) Potental(eV)\n";

    # all profile.dat; 
    my $count = 0; 
    for my $profile (@profiles) { 
        printf $fh "# $profile\n"; 
        
        # potential from file 
        my %md = read_md($profile);     
        
        # re-write with accumulated ionic step 
        for my $istep ( sort { $a <=> $b } keys %md ) { 
            printf $fh "%d\t%d\t%5d\t%10.5f\n", ++$count, $istep, @{$md{$istep}};  
        }

        # record break 
        print $fh "\n\n" unless $profile eq $profiles[-1];  
    }

    # flush
    $fh->close; 

    print "=> Save trajectry as '$output'\n"; 
}

# trajectory files 
if (@trajectories) { 
    my %traj; 

    print "Merging trajectories as:  "; 
    chomp (my $output = <STDIN>); 
    print "\n"; 
    
    for my $traj ( @trajectories ) { 
        # inital hash size
        my $size = keys %traj; 

        # trajectory from previous MD 
        my %xyz  = retrieve_xyz($traj); 
        my @keys = keys  (%xyz); 

        # shift of hash key 
        @keys = map { $_ + $size } @keys; 
        
        # new hash 
        @traj{@keys} = values(%xyz);
            }
    # store joined hash to output 
    save_xyz(\%traj, $output, 1); 
}
