package VASP; 

use strict; 
use warnings; 

use Exporter   qw( import ); 
use List::Util qw( sum max ); 

# symbol 
our @poscar  = qw ( get_cell get_geometry ); 
our @xdatcar = qw ( get_traj ); 
our @oszicar = qw ( get_md ); 
our @outcar  = qw ( get_force ); 
our @aimd    = qw ( read_md sort_md average_md write_md print_extrema ); 

# default import 
our @EXPORT = ( @poscar, @xdatcar, @oszicar, @outcar, @aimd ); 

# tag import 
our %EXPORT_TAGS = (
    poscar  => \@poscar, 
    xdatcar => \@xdatcar, 
    oszicar => \@oszicar,
    outcar  => \@outcar, 
    aimd    => \@aimd, 
); 

##########
# POSCAR #
##########

# arg : 
#   - ref to array of lines (POSCAR/CONTCAR/XDATCAR)
# return : 
#   - ref to 2d array of lattice vectors
#   - ref to array of atom
#   - ref to array of number of atom
#   - type of coordinate (direct/cartesian)
sub get_cell { 
    my ($r2line) = @_; 
    my $title    = shift @$r2line; 
	# scaling constant
	my $scaling  = shift @$r2line; 
    # lattice vectors with scaling contants
    my @lats     = map { [split ' ', shift @$r2line] } 1..3; 
    @lats        = map { [map { $scaling*$_ } @$_] } @lats; 
    # list of element 
	my @atoms    = split ' ', shift @$r2line; 
    # list of number of atoms per element
	my @natoms   = split ' ', shift @$r2line; 
    # selective dynamics ? 
    my $dynamics = shift @$r2line; 
    # direct or cartesian coordinate 
    my $type     = ($dynamics =~ /selective/i) ? shift @$r2line : $dynamics; 
    # backward compatability for XDATCAR produced by vasp 5.2.x 
    if ($type =~ //) { $type = 'direct' }; 

    return ($scaling, \@lats, \@atoms, \@natoms, $type); 
}

# read atomic coordinats block
# arg : 
#   - ref to array of lines 
# return : 
#   - 2d array of atomic coordinates 
sub get_geometry { 
    my ($r2line) = @_; 
    my @coordinates; 
    while ( my $line = shift @$r2line ) { 
        last if $line =~ /^\s+$/; 
        push @coordinates, [ split ' ', $line ]; 
    }

    return @coordinates; 
}

###########
# XDATCAR #
###########

# read atomic coordinate blocks for each ionic step  
# arg : 
#   - ref to array of lines 
# return : 
#   - array of coordinates of each ionic steps 
sub get_traj { 
    my ($r2line) = @_; 
    my (@trajs, @coordinates); 
    while ( my $line = shift @$r2line ) { 
        if ( $line =~ /Direct configuration=|^\s+$/ ) { 
            push @trajs, [@coordinates]; 
            @coordinates = (); 
        } else { 
            push @coordinates, [ split ' ', $line ]; 
        }
    }
    # final coordinates; 
    push @trajs, [ @coordinates ]; 

    return @trajs;  
}

###########
# OSZICAR #
###########

# read istep, T(K), F(eV) from OSZICAR 
# arg : 
#   - ref to array of lines 
# return : 
#   - potential hash (istep => [T, F])
sub get_md { 
    my ($r2line) = @_; 
    my %md; 
    my @md = map {[(split)[0,2,6]]} grep {/T=/} @$r2line;

    # convert array to hash for easier index tracking 
    map { $md{$_->[0]} = [$_->[1], $_->[2]] } @md; 
    
    # total number of entry in hash
    print  "=> Retrieve ISTEP, T(K), and F(eV) from OSZICAR\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %md); 
    
    return %md; 
}


##########
# OUTCAR #
##########

# read total forces of each ion step 
# arg : 
#   - ref to array of lines 
# return : 
#   - array of max forces  
sub get_force { 
    my ($r2line) = @_; 
    # linenr of NION, and force
    my ($lion, @lforces) = grep { $r2line->[$_] =~ /number of ions|TOTAL-FORCE/ } 0..$#$r2line; 
    # number of ion 
    my $nion = (split ' ', $r2line->[$lion])[-1];
    
    # max forces 
    my @max_forces; 
    for my $lforce (@lforces) { 
        # move forward 2 lines 
        $lforce = $lforce+2; 
        # slice $nion from @lines 
        my @forces = map { [(split)[3,4,5]] } @{$r2line}[$lforce .. $lforce+$nion-1]; 
        # max forces 
        my $max_force = max(map {sqrt($_->[0]**2+$_->[1]**2+$_->[2]**2) } @forces); 
        push @max_forces, $max_force; 
    }
    
    return @max_forces;  
}

########
# AIMD #
########

# istep, T(K) and F(eV) from output of get_potential 
# arg : 
#   - profile.dat 
# return : 
#   - potential hash (istep => [T,F])
sub read_md { 
    my ($input) = @_; 
    my %md; 
    print "=> Retrieve potential profile from $input\n"; 
    open PROFILE, '<', $input or die "Cannot open $input\n"; 
    while ( <PROFILE> ) { 
        next if /#/; 
        next if /^\s+/; 
        my ($istep, $temp, $pot) = (split)[0,-2,-1]; 
        $md{$istep} = [ $temp, $pot ]; 
    }

    printf "=> Hash contains %d entries\n\n", scalar(keys %md); 
    return %md; 
}

# sort the potential profile for local minimum and maximum 
# arg : 
#   - ref to potential hash (istep => [T,F])
#   - period of ionic steps for sorting  
# return : 
#   - ref to array of local minima
#   - ref to array of local maxima
sub sort_md { 
    my ($md, $periodicity) = @_; 
    my (@minima, @maxima); 
    # enumerate ionic steps
    my @nsteps = sort { $a <=> $b } keys %$md; 
    # split according to periodicity
    while ( my @period = splice @nsteps, 0, $periodicity ) { 
        # copy the sub hash (not optimal)
        my %sub_md; 
        @sub_md{@period} = @{$md}{@period}; 
        my ($local_minimum, $local_maximum) = (sort { $md->{$a}[1] <=> $md->{$b}[1] } keys %sub_md)[0,-1];  
        push @minima, $local_minimum; 
        push @maxima, $local_maximum;  
    }

    return (\@minima, \@maxima); 
}

# moving averages of potential profile 
# ref: http://mathworld.wolfram.com/MovingAverage.html
# arg: 
#   - ref to potential hash (istep => [T,F])
#   - period of ionic step to be averaged 
#   - output file 
# return: null
sub average_md { 
    my ($r2md, $period, $output) = @_; 
    # extract array of potentials (last column)
    my @potentials = map { $r2md->{$_}[-1] } sort{ $a <=> $b } keys %$r2md; 
    
    # total number of averages point
    my $naverage = scalar(@potentials) - $period + 1; 

    # calculating moving average 
    print "=> $output: Short-time averages of potential energy over period of $period steps\n"; 

    open OUTPUT, '>', $output or die "Cannot write to $output\n"; 
    my $index = 0; 
    for (1..$naverage) { 
        my $average = (sum(@potentials[$index..($index+$period-1)]))/$period; 
        printf OUTPUT "%d\t%10.5f\n", ++$index, $average; 
    }
    close OUTPUT; 

    return; 
}

# print potential profile to file 
# arg: 
#   - ref to potential hash (istep => [T,F])
#   - output file 
sub write_md { 
    my ($md, $file) = @_; 
    open OUTPUT, '>', $file; 
    print OUTPUT "# Step  T(K)   F(eV)\n"; 
    map { printf OUTPUT "%d  %.1f  %10.5f\n", $_, @{$md->{$_}} } sort {$a <=> $b} keys %$md;  
    close OUTPUT; 

    return; 
}

# last evaluated expression 
1;
