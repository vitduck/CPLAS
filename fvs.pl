#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 

use Util         qw( view_eps view_png ); 
use XYZ          qw( xmakemol ); 
use Math::Linalg qw( length ); 

use Data::Dumper; 

my @usages = qw(NAME SYSNOPSIS OPTIONS); 

# POD 
=head1 NAME 
 
fvs.pl: file visualizer (xyz/eps/png)

=head1 SYNOPSIS

fvs.pl [-h] [-x] [-p] [-x]

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit

=item B<-e>

eps files selection

=item B<-p>

png files selection

=item B<-x>

xyz files selection

=back

=cut

# default optional arguments 
my $help = 0;
my $menu = 0; 
my $format = '';  

# sub_ref table
my %view = (
    eps => \&view_eps, 
    png => \&view_png, 
    xyz => \&xmakemol, 
); 

# default output 
if ( @ARGV == 0 ) { pod2usage(-verbose => 1) }; 

# parse optional arguments 
GetOptions(
    'h' => \$help, 
    'e' => sub { $format = 'eps' }, 
    'p' => sub { $format = 'png' }, 
    'x' => sub { $format = 'xyz' }, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }  

# construct table 
my @files = <*.$format>; 

# no available file
if ( @files == 0 ) { pod2usage(-verbose => 99, -section => \@usages) }  

my %table = map { $_+1, $files[$_] } 0..$#files;  

# print table
print "\n"; 
my $length = length(keys %table); 
map { printf "[%${length}d]  %s\n", $_, $table{$_} } sort { $a <=> $b } keys %table; 

# choice loop
while (1) { 
    print "=> "; 
    # remove newline, spaces, etc
    chomp (my $choice = <STDIN>); 
    
    # glob :) 
    # launch all files 
    if ( $choice eq '*' ) { 
        map { $view{$format}->($_) } @files; 
        last; 
    # multiple choice
    } else {  
        my @choices = grep exists $table{$_}, (split ' ', $choice); 
        print "@choices\n"; 
        #sub deref
        for ( @choices ) { $view{$format}->($table{$_}) } 
        last; 
    }
}
