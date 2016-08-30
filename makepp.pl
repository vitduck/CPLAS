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
use feature  qw/switch/; 
use experimental qw/smartmatch/; 

# Moose class 
use VASP::POTCAR; 

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 
 
makepp.pl: generate VASP pseudo potential 

=head1 SYNOPSIS

makepot.pl [-h] [-i] [-e PAW_PBE] C H O 

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-i> 

List information regarding POTCAR 

=item B<-e> 

Available potentials: PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA

=back 

=cut 

# default optional arguments 
my $mode;  
my $exchange = 'PAW_PBE'; 

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }

# optional args
GetOptions( 
    'h'   => sub { $mode = 'help' }, 
    'i'   => sub { $mode = 'info' }, 
    'e=s' => \$exchange, 
) or pod2usage(-verbose => 1); 

given ( $mode ) { 
    when ( 'help' ) { pod2usage(-verbose => 99, -section => \@usages) }
    when ( 'info' ) { VASP::POTCAR->new->info }  
    default { 
        my $PP = VASP::POTCAR->new(element => [@ARGV], exchange => $exchange); 
        $PP->make_potcar; 
        $PP->info; 
    } 
} 
