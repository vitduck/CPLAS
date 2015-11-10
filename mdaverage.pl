#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long;  
use Pod::Usage; 

use VASP qw/read_md average_md/; 

my @usages = qw/NAME SYSNOPSIS OPTIONS/; 

# POD 
=head1 NAME 
 
mdaverage.pl: moving averages for each period of MD 

=head1 SYNOPSIS

mdaverage.pl [-h] [-p] <profile> [-n 1000]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit

=item B<-p> 

Potential file to be averaged (default: profile.dat)

=item B<-n>

number of ion steps to be averaged (default: 1000)

=back 

=cut

# default optional arguments 
my $help    = 0; 
my $profile = 'profile.dat';  
my $output  = 'averages.dat'; 
my $period  = 1000; 

# parse optional arguments 
GetOptions(
    'h'   => \$help, 
    'p=s' => \$profile, 
    'n=i' => \$period
) or pod2usage(-verbose => 1);

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# potential from profile
my %md = read_md($profile); 

# moving average 
average_md($output,\%md, $period);  
