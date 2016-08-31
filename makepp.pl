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
use warnings FATAL => 'all'; 
use feature qw/switch/; 
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

=item B<--help, -h>

Print the help message and exit.

=item B<--list, -l> 

List information of POTCAR

=item B<--exchange, -e> 

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
    'help'       => sub { $mode = 'help' }, 
    'list'       => sub { $mode = 'list' }, 
    'exchange=s' => \$exchange, 
) or pod2usage(-verbose => 1); 

given ( $mode ) { 
    when ( 'help' ) { pod2usage(-verbose => 99, -section => \@usages) }
    when ( 'list' ) { VASP::POTCAR->new->info }  
    default { 
        my $PP = VASP::POTCAR->new(element => [@ARGV], exchange => $exchange); 
        $PP->make_potcar; 
        $PP->info; 
    } 
} 
