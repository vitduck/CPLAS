package Vasp; 

use strict; 
use warnings; 

use Exporter qw(import); 
use List::Util qw(sum max); 
use Storable qw(store retrieve); 

# symbol 
our @input  = qw( get_line get_cell get_geometry ); 
our @output = qw( get_traj get_potential get_force ); 
our @xyz    = qw( make_cell make_xyz view_xyz get_distance ); 
our @md     = qw( get_potential_file sort_potential average_potential ); 
our @store  = qw( save_xyz retrieve_xyz ); 
our @print  = qw( print_minmax print_header print_coordinate print_potential ); 

# default import 
our @EXPORT = ( @input, @output, @xyz, @md, @store, @print );  

# tag import 
our %EXPORT_TAGS = (
    input  => \@input, 
    output => \@output, 
    xyz    => \@xyz,
    md     => \@md, 
    store  => \@store, 
    print  => \@print, 
); 

#########
# INPUT #
#########
# read lines of file to array 
# arg : 
#   - file 
# return : 
#   - array of lines 
sub get_line { 
    my ($input) = @_; 
    open INPUT, '<', $input or die "Cannot open $input\n"; 
    chomp ( my @lines = <INPUT> ); 
    close INPUT; 

    return @lines; 
}

# read cell information block
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

##########
# OUTPUT #
##########
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

# read istep, T(K), F(eV) from OSZICAR 
# arg : 
#   - ref to array of lines 
# return : 
#   - potential hash (istep => [T, F])
sub get_potential { 
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

#######
# XYZ #
#######
# atomic label, total atom for xyz
# arg : 
#   - ref to array of atomic labels 
#   - ref to array of numbers of atoms
#   - ref to expansion array x,y,z
# return: 
#   - ref to array of expanded atomic label 
#   - ref to array of expaned numbers of atoms 
#   - total number of atom in supercell 
sub make_cell { 
    my ($r2atom, $r2natom, $nx, $ny, $nz) = @_; 
    # ex: sx = 2 if $nx = [1..2] 
    # ex: ex = 3 if $nx = [-1..1] (for pair correlation)
    my ($sx, $sy, $sz) = map { scalar @$_ } ($nx, $ny, $nz); 
    # natom for super cell 
    my @natom = map { $_ * $sx * $sy * $sz } @$r2natom; 
    # atomic label for super cell 
    my @label  = map {($r2atom->[$_]) x $natom[$_]} 0..$#$r2atom;  
    # total number of atom 
    my $ntotal = sum( @natom ); 

    return (\@label, \@natom, $ntotal); 
}

# convert POSCAR/CONTCAR/XDATCAR to xyz 
# arg : 
#   - output file handler 
#   - scaling constant 
#   - ref to 2d array of lattive vectors 
#   - ref to 1d array of expanded atomic labels 
#   - coordinate type (direct of cartesian) 
#   - ref to 2d array of atomic coordinates
#   - shift coordinate to center of cell ? 
#   - ref to expansion array x,y,z
# return: 
#   - 2d array of cartesian coordinates
sub make_xyz { 
    my ($fh, $scaling, $r2lat, $r2label, $type, $r2coor, $centralized, $nx, $ny, $nz) = @_; 
    my ($x, $y, $z, @xyz);  

    # loop trough all ionic steps 
    my $index = 0; 
    for my $atom ( @$r2coor ) { 
        # centralize coordinate 
        if ( $centralized ) {  
            $atom->[0] -= 1.0 if $atom->[0] > 0.5; 
            $atom->[1] -= 1.0 if $atom->[1] > 0.5; 
            $atom->[2] -= 1.0 if $atom->[2] > 0.5; 
        }
        # expand the supercell
        for my $ix (@$nx) { 
            for my $iy (@$ny) { 
                for my $iz (@$nz) { 
                    # write xyz
                    if ( $type =~ /D/i ) { 
                        # convert to cartesian
                        $x = $r2lat->[0][0]*$atom->[0] + $r2lat->[1][0]*$atom->[1] + $r2lat->[2][0]*$atom->[2]; 
                        $y = $r2lat->[0][1]*$atom->[0] + $r2lat->[1][1]*$atom->[1] + $r2lat->[2][1]*$atom->[2]; 
                        $z = $r2lat->[0][2]*$atom->[0] + $r2lat->[1][2]*$atom->[1] + $r2lat->[2][2]*$atom->[2]; 
                        # super cell 
                        $x += $scaling*($ix*$r2lat->[0][0] + $iy*$r2lat->[1][0] + $iz*$r2lat->[2][0]); 
                        $y += $scaling*($ix*$r2lat->[0][1] + $iy*$r2lat->[1][1] + $iz*$r2lat->[2][1]); 
                        $z += $scaling*($ix*$r2lat->[0][2] + $iy*$r2lat->[1][2] + $iz*$r2lat->[2][2]); 
                    } else { 
                        # super cell 
                        $x = $scaling*$atom->[0] + $ix*$r2lat->[0][0] + $iy*$r2lat->[1][0] + $iz*$r2lat->[2][0]; 
                        $y = $scaling*$atom->[1] + $ix*$r2lat->[0][1] + $iy*$r2lat->[1][1] + $iz*$r2lat->[2][1]; 
                        $z = $scaling*$atom->[2] + $ix*$r2lat->[0][2] + $iy*$r2lat->[1][2] + $iz*$r2lat->[2][2]; 
                    }
                    # print to output file via $fh 
                    print_coordinate($fh, $r2label->[$index], $x, $y, $z); 
                    push @xyz, [ $r2label->[$index++], $x, $y, $z ]; 
                }
            }
        }
    }

    return @xyz; 
}

# distance between two atom
# arg : 
#   - ref to two cartesian vectors 
# return : 
#   - distance 
sub get_distance { 
    my ($xyz1, $xyz2) = @_; 
    my $d = sqrt(($xyz1->[1]-$xyz2->[1])**2 + ($xyz1->[2]-$xyz2->[2])**2 + ($xyz1->[3]-$xyz2->[3])**2); 

    return $d; 
}

# visualize xyz file 
# arg : 
#   - xyz file 
#   - quiet mode ? 
# return : null
sub view_xyz { 
    my ($file, $quiet) = @_; 
    unless ( $quiet ) { 
        print "=> Launching xmakemol ...\n"; 
        if ( $ENV{DARK} ) { 
            exec "xmakemol -c '#3F3F3F' -f $file >/dev/null 2>&1 &" 
        } else { 
            exec "xmakemol -f $file >/dev/null 2>&1 &" 
        }
    }
}

######
# MD #
######
# istep, T(K) and F(eV) from output of get_potential 
# arg : 
#   - profile.dat 
# return : 
#   - potential hash (istep => [T,F])
sub get_potential_file { 
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
sub sort_potential { 
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
sub average_potential { 
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

#########
# PRINT #
#########
# print local minima/maxima of potential profile 
# arg: 
#   - array of mimina/maxima
# return : null 
sub print_minmax { 
    my @indexes = @_; 

    while ( my @sub_indexes = splice @indexes, 0, 5 ) { 
        my $format = "%-d " x scalar(@sub_indexes);  
        printf "$format\n", @sub_indexes; 
    } 

    return; 
}

# print useful information into comment section of xyz file 
# arg: 
#   - file handler 
#   - ref to 2d array of coordinate 
#   - ionic step (istep) 
#   - ref to potential hash (istep => [T,F])
sub print_header { 
    my ($fh, $r2coor, $istep, $r2md) = @_; 
    printf $fh "%d\n#%d:  T= %.1f  F= %-10.5f\n", scalar(@$r2coor), $istep, @{$r2md->{$istep}}; 

    return ; 
}

# print atomic coordinate block
# arg: 
#   - filehandler 
#   - atomic label 
#   - x, y, and z 
# return : null
sub print_coordinate { 
    my ($fh, $label, $x, $y, $z) = @_; 
    printf $fh "%-2s  %7.3f  %7.3f  %7.3f\n", $label, $x, $y, $z; 

    return; 
}

# print potential profile to file 
# arg: 
#   - ref to potential hash (istep => [T,F])
#   - output file 
sub print_potential { 
    my ($md, $file) = @_; 
    open OUTPUT, '>', $file; 
    print OUTPUT "# Step  T(K)   F(eV)\n"; 
    map { printf OUTPUT "%d  %.1f  %10.5f\n", $_, @{$md->{$_}} } sort {$a <=> $b} keys %$md;  
    close OUTPUT; 

    return; 
}

#########
# STORE #
#########
# save trajectory to disk
# arg : 
#   - ref to trajectory (array of ref to 2d coordinate) 
#   - stored output
# return: null
sub save_xyz { 
    my ($xyz, $output, $save) = @_; 
    if ( $save ) { 
        print  "=> Save trajectory as '$output'\n"; 
        printf "=> Hash contains %d entries\n", scalar(keys %$xyz); 
        store $xyz => $output 
    }
}

# retrieve trajectory to disk
# arg : 
#   - stored data 
# return: null 
sub retrieve_xyz { 
    my ($stored_xyz) = @_; 
    # trajectory is required 
    die "$stored_xyz does not exists\n" unless -e $stored_xyz; 
    # retored traj as hash reference 
    my $r2xyz = retrieve($stored_xyz); 
    print  "=> Retrieve trajectory from '$stored_xyz'\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %$r2xyz); 

    return $r2xyz; 
}

# last evaluated expression 
1; 
