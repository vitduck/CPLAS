#!/usr/bin/env perl 

use strict; 
use warnings; 

use Vasp qw(get_line get_force); 

my @lines  = get_line('OUTCAR'); 
my @forces = get_force(\@lines); 

# print max forces 
my $count = 0; 
my $digit = length(scalar(@forces)); 
while (my @sub_forces = splice @forces, 0, 5) { 
    map { printf "%${digit}d: f = %7.3e  ", ++$count, $_ } @sub_forces; 
    print "\n"; 
}
