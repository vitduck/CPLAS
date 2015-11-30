#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Dumper; 
use Getopt::Long; 
use Pod::Usage; 

use Math::Linalg qw(length); 
use VASP qw(read_poscar read_force); 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
wtf.pl: what the (Hellmann-Feynman) forces (VASP 5) 

=head1 SYNOPSIS

wtf.pl [-h] [-s] [-i OUTCAR] -p 

=head1 OPTIONS

=over 8 

=item B<-h> 

Print the help message and exit.

=item B<-n> 

Number of column in force table 

=item B<-i>

Input file (default: OUTCAR) 

=item B<-p>

Plot the force 

=back 

=cut

# default optional arguments 
my $help  = 0; 
my $ncol  = 5; 
my $input = 'OUTCAR'; 
my $plot  = 0;  

GetOptions(
    'h'   => \$help, 
    'n=i' => \$ncol,
    'i=s' => \$input,
    'p'   => \$plot,  
) or pod2usage(-verbose => 1); 

# help message 
if ($help) { pod2usage(-verbose => 99, -section => \@usages) }

# check selective tags in 
my (undef, undef, undef, undef, undef, undef, undef, $geometry) = read_poscar(); 

# frozen atom 
my @frozen = grep { ( grep $_ =~ /F/, @{$geometry->[$_]} ) == 3 } 0..$#$geometry; 

# collect forces 
my @forces = read_force($input, \@frozen);

# table format
my $nrow = @forces % $ncol ? int(@forces/$ncol)+1 : @forces/$ncol; 

# sort force indices based on modulus 
my @indices = sort { $a % $nrow <=> $b % $nrow } 0..$#forces; 

# print forces
my $digit   = length(scalar(@forces)); 

for my $i (0..$#indices) { 
    printf "%${digit}d: f = %.2e    ", $indices[$i]+1, $forces[$indices[$i]]; 
    
    # the last of us 
    if ($i == $#indices) { last  }  
    
    # break new line due to index wrap around
    if ($indices[$i] > $indices[$i+1] or $ncol == 1) { print "\n" }  
}

# trailing newline 
print "\n"; 
