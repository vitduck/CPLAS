package VASP; 

use strict; 
use warnings; 

use IO::File; 
use List::Util qw( sum max ); 
use File::Basename; 
use File::Spec::Functions qw( catfile ); 
use Storable qw( store retrieve ); 
use Exporter qw( import ); 

use Math qw( max_length print_vec print_mat mat_mul );
use Periodic; 

# symbol 
our @poscar  = qw ( read_cell read_geometry print_poscar );
our @potcar  = qw ( read_potcar select_potcar make_potcar print_potcar_elem ); 
our @xdatcar = qw ( read_traj save_traj retrieve_traj  ); 
our @oszicar = qw ( read_profile ); 
our @doscar  = qw ( read_doscar print_doscar sum_dos ); 
our @outcar  = qw ( read_force read_phonon_eigen ); 
our @aimd    = qw ( read_md sort_md average_md write_md print_extrema ); 

# default import 
our @EXPORT = ( @poscar, @potcar, @xdatcar, @oszicar, @doscar, @outcar, @aimd ); 

# tag import 
our %EXPORT_TAGS = (
    poscar  => \@poscar, 
    xdatcar => \@xdatcar, 
    oszicar => \@oszicar,
    doscar  => \@doscar, 
    outcar  => \@outcar, 
    aimd    => \@aimd, 
); 

#--------#
# POSCAR #
#--------#

# args 
# -< ref to array of lines (POSCAR/CONTCAR/XDATCAR)
# return 
# -> structure name 
# -> scaling 
# -> ref to 2d array of lattice vectors
# -> ref to array of atom
# -> ref to array of number of atom
# -> selective dynamic (0 or 1)
# -> type of coordinate (direct/cartesian)
sub read_cell { 
    my ($line) = @_;  

    my  ($title, $scaling, $lat, $atom, $natom, $dynamics, $type); 
    $title   = shift @$line; 
	# scaling constant
	$scaling = shift @$line; 
    # lattice vectors with scaling contants
    $lat     = [ map { [split ' ', shift @$line] } 1..3 ]; 
    # scaled lattice vector
    $lat     = mat_mul($scaling, $lat);  
    # array of element 
	$atom    = [ split ' ', shift @$line ]; 
    # array of number of atoms per element
	$natom   = [ split ' ', shift @$line ]; 
    # selective dynamics ? 
    $dynamics = shift @$line; 
    # direct or cartesian coordinate 
    #my $type     = ($dynamics =~ /selective/i) ? shift @$line : $dynamics; 
    if ( $dynamics =~ /^\s*s/i ) { 
        $type = shift @$line 
    } else { 
        $type     = $dynamics; 
        $dynamics = 0; 
    }
    # backward compatability for XDATCAR produced by vasp 5.2.x 
    #if ($type =~ //) { $type = 'direct' }; 

    return ($title, $scaling, $lat, $atom, $natom, $dynamics, $type); 
}

# read atomic coordinats block
# args 
# -< ref to array of lines 
# return
# -> 2d array of atomic coordinates 
sub read_geometry { 
    my ($line) = @_; 

    my $coordinate; 
    while ( my $atom = shift @$line ) { 
        last if $atom =~ /^\s+$/; 
        # ignore the selective dynamic tag
        #push @$coordinate, [ (split ' ', $atom)[0..2] ]; 
        # read the selective dynamics tag (if possible)
        push @$coordinate, [split ' ', $atom]; 
    }

    return $coordinate; 
}

# args  
# -< file handler 
# -< structure name 
# -< scaling 
# -< ref to 2d array of lattice vectors
# -< ref to array of atom
# -< ref to array of number of atom
# -< selective dynamic (0 or 1)
# -< type of coordinate (direct/cartesian)
# -< ref to 2d array of coordinates 
# return 
# -> null
sub print_poscar { 
    my ($fh, $title, $scaling, $lat, $atom, $natom, $dynamics, $type, $coordinate) = @_; 

    my %format = ( 
        string  => '5s', 
        integer => '6d', 
        real    => '22.16f', 
    ); 

    # coordinate format 
    my $cformat; 

    # print POSCAR header 
    printf $fh "%s\n", $title; 
    printf $fh "%f\n", $scaling; 
    print_mat($lat, $format{real}, $fh); 
    print_vec($atom, $format{string}, $fh); 
    print_vec($natom, $format{integer}, $fh); 
    printf $fh "%s\n", $dynamics if $dynamics; 
    printf $fh "%s\n" , $type; 

    if ( $dynamics ) { 
        # check number of row in $coordinate 2d matrix 
        # 3: no dynamic tag 
        # 6: with dynamic tag 
        if ( @{$coordinate->[0]} == 3 ) { 
            map { push @$_, qw(T T T) } @$coordinate; 
        }
        # set the approriate format 
        $cformat = "%$format{real}"x3 . "%$format{string}"x3 . "%$format{integer}\n"; 
    } else { 
        $cformat = "%$format{real}"x3 . "%$format{integer}\n";  
    }

    # print POSCAR geometry 
    my $count = 0; 
    for my $atom ( @$coordinate ) { 
        printf $fh $cformat, @$atom, ++$count;  
    }
    
    return; 
}

#--------#
# POTCAR #
#--------#

# read list of PP in POTCAR 
# args  
# -< ref to POTCAR lines 
# return 
# -> hash of pp type PAW_PBE => [ element, date ];  
sub read_potcar { 
    my ($line) = @_; 

    my %pp;  
    my $shell_config; 
    for( @$line ) { 
        if ( /VRHFIN/ ) { 
            $shell_config = (split /:/)[-1]; 

        }
        if ( /TITEL/ ) { 
            my ($type, $element, $date) = (split)[2,3,4]; 
            push @{$pp{$type}}, [$element, $shell_config, $date]; 
        }
    }

    return %pp;  
} 

# print elements in POTCAR 
# args 
# -< POTCAR element hash 
# return 
# -> null 
sub print_potcar_elem { 
    my %pp = @_; 

    # PP type 
    my ($type) = keys %pp; 

    # string format
    my $elength = max_length(map $_->[0], @{$pp{$type}});  
    my $slength = max_length(map $_->[1], @{$pp{$type}});  

    for my $type ( keys %pp ) { 
        print "=> Pseudopotential: $type\n"; 
        for my $element ( @{$pp{$type}} ) { 
            printf "%-${elength}s |%-${slength}s | %-s\n", @$element; 
        }
    }

    return; 
}

# POTCAR selector 
# args 
# -< directory of VASP pseudo potential 
# -< type of potential 
# -< element in periodic table 
# -< ref of potcar list
# return 
# -> null 
sub select_potcar { 
    my ($dir, $potential, $element) = @_; 
    
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
            print "\n"; 
            return catfile($dir, $potential, $choice, 'POTCAR'); 
        }
    }

    return; 
}

# write new POTCAR 
# args 
# -< filehandle for POTCAR 
# -< element's POTCAR file 
# return 
# -> null 
sub make_potcar { 
    my ($fh, $potcar) = @_; 

    my $elem_fh = IO::File->new($potcar, 'r') or die "Cannot open $potcar\n";  
    print $fh (<$elem_fh>); 
    $elem_fh->close; 
    
    return; 
}

#---------#
# XDATCAR #
#---------#

# read atomic coordinate blocks for each ionic step  
# args 
# -< slurped XDATCAR lines  
# return
# -> array of coordinates of each ionic steps 
sub read_traj { 
    my ($line) = @_; 

    my ($title, $scaling, $lat, $atom, $natom); 
    my ($cell, @trajs) = split /Direct configuration=.*\d+\n/, $line; 
    
    # cell
    ($title, $scaling, @$lat[0..2], $atom, $natom) = split /\n/, $cell;  
    # 1d array -> 2d array 
    $lat   = [ map [split ' ', $_], @$lat ]; 
    # string -> 1d array 
	$atom  = [ split ' ', $atom ]; 
	$natom = [ split ' ', $natom ]; 

    return ($title, $scaling, $lat, $atom, $natom, \@trajs);  
}

# save trajectory to disk
# args  
# -< ref to trajectory (array of ref to 2d coordinate) 
# -< stored output
# return: 
# -> null
sub save_traj { 
    my ($traj, $output, $save) = @_; 

    if ( $save ) { 
        print  "=> Save trajectory as '$output'\n"; 
        printf "=> Hash contains %d entries\n", scalar(keys %$traj); 
        store $traj => $output;  
    }

    return; 
}

# retrieve trajectory to disk
# args 
# -< stored data 
# return 
# -> traj hash 
sub retrieve_traj { 
    my ($stored_traj) = @_; 

    # trajectory is required 
    die "$stored_traj does not exists\n" unless -e $stored_traj; 
    # retored traj as hash reference 
    my $traj = retrieve($stored_traj); 
    print  "=> Retrieve trajectory from '$stored_traj'\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %$traj); 

    return %$traj; 
}

#---------#
# OSZICAR #
#---------#

# read istep, T(K), F(eV) from OSZICAR 
# args  
# -< ref to array of lines 
# return 
# -> potential hash (istep => [T, F])
sub read_profile { 
    my ($line) = @_; 

    my %md; 
    my @md = map {[(split)[0,2,6]]} grep {/T=/} @$line;

    # convert array to hash for easier index tracking 
    map { $md{$_->[0]} = [$_->[1], $_->[2]] } @md; 
    
    # total number of entry in hash
    print  "=> Retrieve ISTEP, T(K), and F(eV) from OSZICAR\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %md); 
    
    return %md; 
}

#--------# 
# DOSCAR #
#--------# 

# read DOSCAR
# args 
# -< ref to array of DOSCAR lines 
# return 
# -> ref to array of total dos 
# -> ref to array of projected dos 
sub read_doscar { 
    my ($line) =@_; 

    # number of ions 
    my $nion = (split ' ', shift @$line)[0]; 
    
    # cleave the mysterious heade
    shift @$line for 1..4; 

    # min, max, nedos, fermi, spin ? 
    my $header = shift @$line; 
    my ($min, $max, $nedos, $fermi, $wth) = split ' ', $header; 
    
    # total dos, ldos 
    my @tdos = map {[split]} splice @$line, 0, $nedos; 
    my @ldos = map { [map { [split] } splice @$line, 0, $nedos+1] } 1..$nion; 
    
    return (\@tdos, \@ldos);  
}

# print LDOS 
# args 
# -< filehandler 
# -< ref to 2d array of ldos 
# return 
# -> null
#sub print_ldos { 
    #my ($fh, $ldos) = @_; 
   
    #my $format = ("%.3f  ") x 14; 
    #for my $dos ( @$ldos ) { 
        ## calculate s, p, d, total sum 
        #my $sum_s = $ldos->[1]; 
        #my $sum_p = sum(@{$ldos}[2..4]); 
        #my $sum_d = sum(@{$ldos}[5..9]);
        #my $sum   = $sum_s + $sum_p + $sum_d; 
        #printf $fh "$format\n", @$ldos, $sum_s, $sum_p, $sum_d, $sum; 

    #}

    #return; 
#}

#--------#
# OUTCAR #
#--------#

# read total forces of each ion step 
# args 
# -< ref to array of OUTCAR lines 
# return 
# -> array of max forces  
sub read_force { 
    my ($line) = @_; 

    # linenr of NION, and force
    my ($lion, @lforces) = grep { $line->[$_] =~ /number of ions|TOTAL-FORCE/ } 0..$#$line; 
    # number of ion 
    my $nion = (split ' ', $line->[$lion])[-1];
    
    # max forces 
    my @max_forces; 
    for my $lforce (@lforces) { 
        # move forward 2 lines 
        $lforce = $lforce+2; 
        # slice $nion from @lines 
        my @forces = map { [(split)[3,4,5]] } @{$line}[$lforce .. $lforce+$nion-1]; 
        # max forces 
        my $max_force = max(map {sqrt($_->[0]**2+$_->[1]**2+$_->[2]**2) } @forces); 
        push @max_forces, $max_force; 
    }
    
    return @max_forces;  
}

# read the eigenvectors and eigenvalues of dynamical matrix 
# args
# -< ref to array of OUTCAR lines 
# return 
# -> ref to hash: 
# 1 => { value  => ..., 
#        vector => { [dx dy dz] },  
#      }, 
# 2 => ...
sub read_phonon_eigen { 
    my ($line) = @_; 

    my %eigen; 

    # linenr of DOF and eigen (similar approach to read_force()) 
    my ($ldof, $leigen) = grep { $line->[$_] =~ /DOF|Eigenvectors and eigenvalues/ } 0..$#$line; 
    # number of degree of freedom 
    my $ndof = (split ' ', $line->[$ldof])[-1];
    
    # read eigen{vectors,value} 
    $leigen += 3; 
    for my $dof (1..$ndof) { 
        while (1) {  
            my $line = $line->[++$leigen]; 
            # skip the eigenvector header 
            if ( $line =~ /X\s+Y\s+Z\s+/ ) { next } 
            # exit at blank line 
            if ( $line =~ /^\s+$/ ) { last }  
            # eigenvalue 
            if ( $line =~ /\d+\s+f/ ) { 
                $eigen{$dof}{f} = (split ' ', $line)[-2]; 
                next; 
            }
            # eigenvector 
            push @{$eigen{$dof}{dxyz}}, [(split ' ', $line)[-3,-2,-1]]; 
        }
    }
    
    return \%eigen; 
}

#------#
# AIMD #
#------#

# istep, T(K) and F(eV) from output of get_potential 
# args  
# -< profile.dat 
# return 
# -> potential hash (istep => [T,F])
sub read_md { 
    my ($input) = @_; 
   
    my %md; 
    print "=> Retrieve potential profile from $input\n"; 
    
    my $fh = IO::File->new($input, 'r') or die "Cannot open $input\n";  
    while ( <$fh> ) { 
        next if /#/; 
        next if /^\s+/; 
        my ($istep, $temp, $pot) = (split)[0,-2,-1]; 
        $md{$istep} = [ $temp, $pot ]; 
    }
    $fh->close; 

    printf "=> Hash contains %d entries\n\n", scalar(keys %md); 

    return %md; 
}

# sort the potential profile for local minimum and maximum 
# args 
# -< ref to potential hash (istep => [T,F])
# -< period of ionic steps for sorting  
# return
# -> ref to array of local minima
# -> ref to array of local maxima
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
# args 
# -< ref to potential hash (istep => [T,F])
# -< period of ionic step to be averaged 
# -< output file 
# return 
# -> null
sub average_md { 
    my ($md, $period, $output) = @_; 

    # extract array of potentials (last column)
    my @potentials = map { $md->{$_}[-1] } sort{ $a <=> $b } keys %$md; 
    
    # total number of averages point
    my $naverage = scalar(@potentials) - $period + 1; 

    # calculating moving average 
    print "=> $output: Short-time averages of potential energy over period of $period steps\n"; 

    my $index = 0; 
    my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  
    for (1..$naverage) { 
        my $average = (sum(@potentials[$index..($index+$period-1)]))/$period; 
        printf $fh "%d\t%10.5f\n", ++$index, $average; 
    }
    $fh->close; 

    return; 
}

# print potential profile to file 
# args  
# -< ref to potential hash (istep => [T,F])
# -< output file 
# return 
# -> null
sub write_md { 
    my ($md, $output) = @_; 

    my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  
    print $fh "# Step  T(K)   F(eV)\n"; 
    map { printf $fh "%d  %.1f  %10.5f\n", $_, @{$md->{$_}} } sort {$a <=> $b} keys %$md;  
    $fh->close; 

    return; 
}

# last evaluated expression 
1;
