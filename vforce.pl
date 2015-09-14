#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( get_line ); 
use VASP    qw( get_force); 

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
vforce.pl: total Hellmann-Feynman forces (VASP 5) 

=head1 SYNOPSIS

vforce.pl [-h] [-s]

=head1 OPTIONS

=over 8 

=item B<-h> 

Print the help message and exit.

=item B<-s> 

Save forces to forces.dat

=back 

=cut

# default optional arguments 
my $help   = 0; 
my $save   = 0; 
my $output = 'forces.dat'; 

GetOptions(
    'h'  => \$help, 
    's'  => \$save, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# collect forces 
my @lines  = get_line('OUTCAR'); 
my @forces = get_force(\@lines); 

# maximum of 5 column 
my $ncol = 5; 
my $nrow = @forces % $ncol ? int(@forces/$ncol)+1 : @forces/$ncol; 

# sort force indices based on modulus 
my @indices = sort { $a % $nrow <=> $b % $nrow } 0..$#forces; 

# print forces
my $digit   = length(scalar(@forces)); 
for my $i ( 0..$#indices ) { 
    printf "%${digit}d: f = %7.3e  ", $indices[$i]+1, $forces[$indices[$i]]; 
    # last of us 
    if ( $i == $#indices ) { last } 
    # break new line due to index wrap around
    if ( $indices[$i] > $indices[$i+1] ) { 
        print "\n"; 
    } 
}

# save force to file 
if ( $save ) { 
    open my $fh, '>', $output; 
    printf $fh "%d\t%7.3e\n", $_+1, $forces[$_] for 0..$#forces; 
    close $fh; 
}
