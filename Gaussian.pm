package Gaussian; 

use Exporter   qw( import ); 
use List::Util qw( sum ); 

use Periodic; 
use XYZ qw( print_coordinate ); 

our @gaussian = qw( read_gaussian print_gaussian ); 

our @EXPORT =  (@gaussian); 

############
# GAUSSIAN #
############

# parse gaussian input (slurp mode) 
# args 
# -< scalar $line 
# return 
# -> option
# -> level of theory 
# -> title 
# -> charge 
# -> spin 
# -> $atom 
# -> $natom 
# -> $geometry
sub read_gaussian { 
    my ($line) = @_; 
    
    # split based on empty lines 
    my ($header, $title, $structure) = split /\n+\s*\n+/, $line; 
    
    # option hash 
    my $option = [grep /\%/, split /\n/, $header]; 

    # theory 
    my ($theory) = grep /#/, split /\n/, $header; 

    # charge, spin and structure 
    my @lines = split /\n/, $structure; 
    my ($charge, $spin) = split ' ', shift @lines; 

    # read the xyz block
    my %struct; 
    for ( @lines ) { 
        my ($element, $x, $y, $z) = split; 
        # initialize coordinate array of element  
        unless ( exists $struct{$element} ) {   
            $struct{$element} = [] 
        }
        push @{$struct{$element}}, [ $x, $y, $z ]; 
    }

    my $atom     = [ sort { $Periodic::table{$a}[0] <=> $Periodic::table{$b}[0] } keys %struct ]; 
    my $natom    = [ map { scalar @{$struct{$_}} } @$atom ];  
    my $geometry = [ map { @{$struct{$_}} } @$atom ]; 

    return ($option, $theory, $title, $charge, $spin, $atom, $natom, $geometry);  
}

# print gaussian input 
# args
# -< fh 
# -< option 
# -< level of theory 
# -< title 
# -< charge 
# -< spin 
# -< $atom 
# -< $natom 
# -< $geometry
# return 
# -> null 
sub print_gaussian { 
    my ($fh, $option, $theory, $title, $charge, $spin, $atom, $natom, $geometry) = @_;  

    # xyz label 
    my @labels = map { ($atom->[$_]) x $natom->[$_] } 0..$#$atom;

    # print header 
    map { printf $fh "%s\n", $_ } @$option; 
    printf $fh "%s\n\n", $theory; 
    printf $fh "%s\n\n", $title; 
    printf $fh "%d  %d\n", $charge, $spin; 

    # print coordinates 
        for  ( 0..$#labels ) { 
        print_coordinate($fh, $labels[$_], @{$geometry->[$_]}); 
    }

    # connectivity 
    printf $fh "\n"; 
    #printf $fh "%d\n", $_ for  1..@labels; 

    return; 
} 

# last evaluated expression 
1; 
