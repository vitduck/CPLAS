#!/usr/bin/env perl 
use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use GenUtil qw( read_line ); 
use VASP    qw( read_potcar select_potcar print_potcar_elem make_potcar );

my @usages = qw( NAME SYSNOPSIS OPTIONS ); 

# POD 
=head1 NAME 
 
makepp.pl: generate VASP pseudo potential 


=head1 SYNOPSIS

makepot.pl [-h] [-l] [-t PAW_PBE] [-e C H O] 

Available potentials: PAW_PBE PAW_GGA PAW_LDA USP_GGA USP_LDA

=head1 OPTIONS

=over 8

=item B<-h>

Print the help message and exit.

=item B<-l>

List the current potentials in POTCAR

=item B<-t> 

Type of pseudopential (default: PAW_PBE) 

=item B<-e> 

List of elements 

=back 

=cut 

# location of PP 
my $dir = '/opt/VASP/POTCAR';  

# default optional arguments 
my $help       = 0; 
my $list       = 0; 
my $potential  = 'PAW_PBE'; 
my @potentials = qw( PAW_PBE PAW_GGA PAW_LDA USP_GGA USP_LDA );  

my $potcar = [];  

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }

# optional args
GetOptions(
    'h'       => \$help, 
    'l'       => sub { print_potcar_elem(read_potcar(read_line('POTCAR'))) },  
    't=s'     => sub { 
        my ($opt, $potential) = @_; 
        # available potentials 
        unless ( grep { $potential eq $_ } @potentials ) {  
            pod2usage(-verbose => 1, -message => "Invalid potential type: $potential\n" ) 
        }
    },
    'e=s{1,}' => sub { 
        my ($opt, $element) = @_; 
        # available elements 
        unless ( exists $Periodic::table{$element} ) {  
            pod2usage(-verbose => 1, -message => "Invalid element: $element\n" ) 
        }
        # iteractive POTCAR selector
        select_potcar($dir, $potential, $element, $potcar);  
    }
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }; 

if (@$potcar) { 
    my $fh = IO::File->new('POTCAR', 'w'); 
    make_potcar($fh, $potcar); 
    $fh->close; 
}
