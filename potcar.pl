#!/usr/bin/env perl 

use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use Data::Printer; 
use VASP::POTCAR; 

# use Carp 'verbose';
# $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use feature qw( switch );   
use experimental qw( smartmatch );  

my @usages = qw( NAME SYSNOPSIS OPTIONS );  

# POD 
=head1 NAME 
 
makepp.pl: generate VASP pseudo potential 

=head1 SYNOPSIS

makepot.pl <info|append|make> [ -e C H O ] [-p PAW_PBE] 

=head1 OPTIONS

=over 16

=item B<-h, --help>

Print the help message and exit.

=item B<-e, --element > 

list of POTCAR's element 

=item B<-p, --potential> 

PAW_PBE | PAW_GGA | PAW_LDA | POT_GGA | POT_LDA

=back 

=cut 

# optional args
GetOptions( 
    \ my %option, 
    'help', 'element=s@{1,}', 'potential=s'
) or pod2usage( -verbose => 1 ); 

# help message 
pod2usage( 
    -verbose => 99, 
    -section => \@usages 
) if @ARGV == 0 or exists $option{ help }; 

# init POTCAR 
my $potcar = VASP::POTCAR->new( 
    exchange => $option{ potential } //= 'PAW_PBE', 
    element  => $option{ element   } //= []
); 

given ( shift @ARGV ) { 
    when ( 'info'   ) { $potcar->info }
    when ( 'append' ) { $potcar->append( $option{ element }->@* ); $potcar->info } 
    when ( 'make'   ) { $potcar->make }
} 
