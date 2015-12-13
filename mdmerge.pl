#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use MD qw( merge_profile merge_traj );  

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
    'p=s{1,}' => \@profiles, 
    't=s{1,}' => \@trajectories, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# profile files
@profiles && do {  
    print "Merging profiles as:  "; 
    chomp (my $output = <STDIN>); 
    print "\n"; 
    
    merge_profile(\@profiles => $output); 
}; 

# trajectory files 
@trajectories && do {  
    print "Merging trajectories as:  "; 
    chomp (my $output = <STDIN>); 
    print "\n"; 
    
    merge_traj(\@trajectories => $output); 

}; 
