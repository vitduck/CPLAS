#!/usr/bin/env perl 
use strict; 
use warnings; 

use IO::File; 
use Getopt::Long; 
use Pod::Usage; 

use Periodic qw/element_name/; 
use VASP qw/read_potcar print_potcar make_potcar/;

my @usages = qw/NAME SYSNOPSIS OPTIONS/; 

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

=item B<-l>

List the current potentials in POTCAR

=item B<-t> 

Type of pseudopential (default: PAW_PBE) 

=item B<-e> 

List of elements 

=back 

=cut 

# location of PP 
my $dir = $ENV{POTCAR}; 

# default optional arguments 
my $help       = 0; 
my $list       = 0; 
my $potential  = 'PAW_PBE'; 
my @potentials = qw/PAW_PBE PAW_GGA PAW_LDA POT_GGA POT_LDA/;  

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }

# location of VASP POTCAR
if ( not defined $dir ) { 
    die "Please export location of POTCAR files in .bashrc\n
    For example: export POTCAR=/opt/VASP/POTCAR\n";
}

my @elements = ( );  

# optional args
GetOptions(
    'h' => \$help, 
    'l' => sub { 
        my @pp = read_potcar();  
        print_potcar(@pp); 
    },  
    't=s' => sub { 
        my ( $opt, $arg ) = @_; 
        # available potentials 
        if ( grep { $arg eq $_ } @potentials ) {  
            $potential = $arg; 
        } else { 
            pod2usage(-verbose => 1, -message => "Invalid potential type: $arg");  
        }
    },
    'e=s{1,}' => sub { 
        my ( $opt, $element ) = @_; 
        # available elements 
        unless ( element_name($element) ) {  
            pod2usage(-verbose => 1, -message => "Invalid element: $element"); 
        }
        # populate @elements 
        push @elements, $element; 
    }
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }; 

# generate POTCAR 
if ( @elements ) { make_potcar('POTCAR', $dir, $potential, @elements) }
