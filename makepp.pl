#!/usr/bin/env perl 

# core 
use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

# cpan 
use Data::Printer; 

# pragma 
use autodie; 
use strict; 
use warnings; 

# Moose class 
use VASP::POTCAR; 

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 
 
makepp.pl: generate VASP pseudo potential 

=head1 SYNOPSIS

makepot.pl [-h] [-l] [-t PAW_PBE] [-e C H O] 

Available potentials: PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-t> 

Type of pseudopential (default: PAW_PBE) 

=item B<-e> 

List of elements 

=back 

=cut 

# default optional arguments 
my $help     = 0; 
my $exchange = 'PAW_PBE'; 
my @elements = ();  

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }

# optional args
GetOptions(
    'h'       => \$help, 
    't=s'     => \$exchange,
    'e=s{1,}' => \@elements, 
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }; 

# object construction 
my $POTCAR = VASP::POTCAR->new(elements => \@elements, exchange => $exchange);  

$POTCAR->make_potcar; 
