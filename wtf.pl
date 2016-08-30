#!/usr/bin/env perl 

# core 
use Getopt::Long; 
use Pod::Usage; 

# pragma
use autodie;  
use strict; 
use warnings FATAL => 'all';  

# Moose class 
use VASP::OUTCAR;  

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
wtf.pl: what the (Hellmann-Feynman) forces

=head1 SYNOPSIS

wtf.pl [-h] [-s] [-i OUTCAR] -p 

=head1 OPTIONS

=over 8 

=item B<-h> 

Print the help message and exit.

=item B<-i>

Input file (default: OUTCAR) 

=item B<-c> 

Number of column in force table 

=back 

=cut

# default optional arguments 
my $help  = 0; 
my $ncol  = 5; 
my $input = 'OUTCAR'; 

GetOptions(
    'h'   => \$help, 
    'i=s' => \$input,
    'c=i' => \$ncol,
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# collect forces 
my $outcar = VASP::OUTCAR->new; 
my @forces = $outcar->get_max_forces; 

# table format
my $nrow = @forces % $ncol ? int(@forces/$ncol)+1 : @forces/$ncol; 

# sort force indices based on modulus 
my @indices = sort { $a % $nrow <=> $b % $nrow } 0..$#forces; 

# print forces
my $digit = length(scalar(@forces)); 

for my $i (0..$#indices) { 
    printf "%${digit}d: f = %.2e    ", $indices[$i]+1, $forces[$indices[$i]]; 
    
    # the last of us 
    if ($i == $#indices) { last  }  
    
    # break new line due to index wrap around
    if ($indices[$i] > $indices[$i+1] or $ncol == 1) { print "\n" }  
}

# trailing newline 
print "\n"; 
