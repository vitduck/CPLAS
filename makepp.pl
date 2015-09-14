#!/usr/bin/env perl 

use strict; 
use warnings; 

use Getopt::Long; 
use Pod::Usage; 
use File::Basename; 
use File::Spec::Functions qw( catfile ); 

use Periodic; 

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
my @elements   = (); 
my @potcars; 

# default output 
if ( @ARGV==0 ) { pod2usage(-verbose => 1) }

# optional args
GetOptions(
    'h'       => \$help, 
    'l'       => \$list, 
    't=s'     => \$potential,
    'e=s{1,}' => \@elements
) or pod2usage(-verbose => 1); 

# help message 
if ( $help ) { pod2usage(-verbose => 99, -section => \@usages) }

# available potentials 
unless ( grep { $potential eq $_ } @potentials ) {  
    pod2usage(-verbose => 1, -message => "Invalid potential type\n" ) 
}

# available elements 
for my $element ( @elements ) { 
    pod2usage(-verbose => 1, -message => "Invalid element: $element\n" ) 
    unless exists $Periodic::table{$element}; 
}

# POTCAR generation
for my $element (@elements ) { 
    my @avail_pots = map { basename $_ } grep /\/($element)(\z|\d|_|\.)/, < $dir/$potential/* >;
    printf "=> Pseudopotentials for $Periodic::table{$element}[1]: %s\n", join(' | ', @avail_pots); 
    # Promp user to choose potential 
    while (1) { 
        print "=> Choice: "; 
        # remove newline, spaces, etc
        chomp (my $choice = <STDIN>); 
        $choice =~ s/\s+//g; 
        # fullpath for chosen potential 
        if ( grep { $choice eq $_ } @avail_pots ) { 
            push @potcars, catfile($dir, $potential, $choice, 'POTCAR'); 
            last; 
        }

    }
    print "\n"; 
}

# POTCAR accumulation
if ( @elements and @potcars ) { 
    print "=> Generating POTCAR for @elements\n" if @elements; 
    open OUTPUT, '>', 'POTCAR' or die "Cannot write POTCAR\n"; 
    for my $potcar ( @potcars ) { 
        # element's POTCAR 
        open POTCAR, '<', $potcar or die "Cannot open $potcar\n"; 
        print OUTPUT <POTCAR>; 
        close POTCAR; 
    }
    close OUTPUT; 
}

# potentials in POTCAR
if ( $list ) { 
    print "\n" if @elements; 
    open POTCAR, '<', 'POTCAR' or die "Cannot open POTCAR\n"; 
    print "=> List of elements in POTCAR:\n";  
    while ( <POTCAR> ) { 
        if ( /TITEL/ ) { 
            my ($potential, $element, $date) = (split)[2,3,4]; 
            print "$potential $element $date\n"; 
        }
    }
    close POTCAR; 
}
