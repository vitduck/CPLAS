#!/usr/bin/env perl 

use strict; 
use warnings; 
use feature qw( switch );  
use experimental qw( smartmatch ); 

use IO::File; 
use Data::Printer; 
use Getopt::Long; 
use Pod::Usage; 
use VASP::POTCAR; 

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 
 
makepp.pl: generate VASP pseudo potential 

=head1 SYNOPSIS

makepot.pl [-h] [-i] [-e PAW_PBE] C H O 

=head1 OPTIONS

=over 16

=item B<-h, --help>

Print the help message and exit.

=item B<-l, --list> 

List information of POTCAR

=item B<-e, --exch> 

PAW_PBE | PAW_GGA | PAW_LDA | POT_GGA | POT_LDA

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
    when ( 'help' ) { pod2usage( -verbose => 99, -section => \@usages ) }
    when ( 'list' ) { VASP::POTCAR->new->info }  

    default { 
        my $PP = VASP::POTCAR->new( element => [@ARGV], exchange => $exchange ); 
        $PP->make;  
        $PP->info; 
    } 
} 
