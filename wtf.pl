#!/usr/bin/env perl 

use autodie;  
use strict; 
use warnings FATAL => 'all';  

use Getopt::Long; 
use Pod::Usage; 
use VASP::OUTCAR;  

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
wtf.pl: what the (Hellmann-Feynman) forces

=head1 SYNOPSIS

wtf.pl [-h] [-s] [-i OUTCAR] 

=head1 OPTIONS

=over 16

=item B<-h, --help> 

Print the help message and exit.

=item B<-i, --input>

Input file (default: OUTCAR) 

=item B<-c, --column> 

Number of column of the force table 

=back 

=cut

# default optional arguments 
my $help  = 0; 
my $ncol  = 5; 
my $input = 'OUTCAR'; 

GetOptions(
    'help'     => \$help, 
    'input=s'  => \$input,
    'column=i' => \$ncol,
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# collect forces 
my $outcar = VASP::OUTCAR->new( file => $input );  

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
