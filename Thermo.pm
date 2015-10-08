package Thermo; 

use strict; 
use warnings; 

use Exporter qw( import ); 
use List::Util qw( sum ); 

use GenUtil qw( read_line ); 

our @thermo   = qw( zpe fvib chempot ); 
our @ensemble = qw( bolztmann_factor partition_function occupation );  

our @EXPORT = ( @thermo, @ensemble );

# thermodynamics contant 
my $kb = 8.6173324E-5; 

#--------#
# THERMO #
#--------#

# ZPE energy 
# args
# -< array of eiven values (meV) 
# return 
# -> ZPE 
sub zpe { 
    my (@eigens) = @_; 

    return 0.5*sum(@eigens )/1000;  
}

# vibrational free energy 
# args
# -< temperature (K) 
# -< array of eiven values (meV) 
# return 
# -> F_vib 
sub fvib { 
    my ($T, @eigens) = @_; 
    
    return sum( map $kb*$T*log(1.0-exp((-1e-3*$_)/($kb*$T))), @eigens ); 
}

# chemical potential from JANAF 
# http://kinetics.nist.gov/janaf/
# args
# -< input file (tab formatted) 
# return 
# -> hash of chemical potential 
sub chempot { 
    my ($janaf) = @_;     
    
    my %mu; 
    my $line = read_line($janaf); 
    
    # 1st line: name of gas 
    shift @$line; 
    # 2nd line: table header 
    shift @$line; 
    # 3rd line: H0 ref 
    my $H0 = (split ' ', shift @$line)[4]; 

    while ( my $data = shift @$line ) { 
        my ($T, $S, $H) = (split ' ', $data)[0, 2, 4]; 
        $mu{$T} = (1000*($H-$H0) - $S*$T)/96486;
    }

    return \%mu; 
}

#----------# 
# ENSEMBLE #
#----------# 

# exponential weight 
# args 
# -< dE, dF, chempot, temperature, pressure
# return 
# -> exp[-(dE + dF - (chempot + kB*T*log(P)))/kB*T]
sub boltzmann_factor { 
    my ($dE, $dF, $n, $chempot, $T, $P); 
    
    # Gibbs free energy of adsorption 
    my $dG = $dE + $dF - $n*($chempot + $kb*$T*log($P)); 

    return exp(-$dG/($kb*$T)); 
}

# partion function 
# args 
# -< ref to 2d array [ ...[degenracy, boltzmann] ... ]
# return 
# -> sum over boltzmann factor 
sub partition_function { 
    my @boltzmann_factors = @_; 

    return sum(@boltzmann_factors); 
}

# partion function 
# args 
# -< ref to 2d array [ ...[degenracy, boltzmann] ... ]
# -< partition function
# return 
# -> Sum( degeneracy_i * $bfactor_i )
sub occupation { 
    my ($factor, $z ) = @_; 

    return sum(map $_->[0]*$_->[1], @$factor)/$z;
}

# calculate the 
# last evaluated expression 
1;
