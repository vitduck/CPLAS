package VASP; 

use strict; 
use warnings; 

use Exporter; 
use File::Basename; 
use File::Spec::Functions; 
use IO::File; 
use Storable qw/store retrieve/; 

use Fortran qw/fortran2perl/; 
use Math::Linalg qw/max sum length print_array print_mat mat_mul/;
use Periodic qw/element_name/;  
use Util qw/read_file slurp_file paragraph_file extract_file/; 

our @aimd     = qw/read_md sort_md average_md print_extrema/; 
our @doscar   = qw/read_doscar print_dos sum_dos/; 
our @eigenval = qw/read_band/;  
our @kpoints  = qw/read_kpoints/; 
our @poscar   = qw/read_poscar print_poscar/;
our @potcar   = qw/read_potcar print_potcar make_potcar/; 
our @oszicar  = qw/read_profile print_profile/; 
our @outcar   = qw/read_force read_phonon_eigen/; 
our @xdatcar  = qw/read_traj save_traj retrieve_traj/; 

our @ISA         = qw/Exporter/; 
our @EXPORT      = ( );  
our @EXPORT_OK   = ( @aimd, @doscar, @eigenval, @kpoints, @poscar, @potcar, @oszicar, @outcar, @xdatcar ); 
our %EXPORT_TAGS = ( 
    aimd     => \@aimd, 
    doscar   => \@doscar, 
    eigenval => \@eigenval, 
    kpoints  => \@kpoints, 
    poscar   => \@poscar, 
    potcar   => \@potcar, 
    oszicar  => \@oszicar,
    outcar   => \@outcar, 
    xdatcar  => \@xdatcar, 
); 

#------#
# AIMD #
#------#

# istep, T(K) and F(eV) from output of get_potential 
# args  
# -< profile.dat 
# return 
# -> potential hash (istep => [T,F])
sub read_md { 
    my $file = shift @_ || 'profile.dat'; 

    my %md; 
    for ( read_file($file) ) { 
        next if /#/; 
        next if /^\s+/; 
        my ($istep, $temp, $pot) = (split)[0,-2,-1]; 
        $md{$istep} = [$temp, $pot]; 
    }

    printf "=> Retrieve potential profile from %s\n", $file; 
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
    my ( $md, $periodicity ) = @_; 

    my ( @minima, @maxima ); 

    # enumerate ionic steps
    my @nsteps = sort { $a <=> $b } keys %$md; 

    # split according to periodicity
    while ( my @period = splice @nsteps, 0, $periodicity ) { 
        # copy the sub hash (not optimal)
        my %sub_md; 
        @sub_md{@period} = @$md{@period}; 
        my ( $local_minimum, $local_maximum ) = ( sort { $md->{$a}[1] <=> $md->{$b}[1] } keys %sub_md )[0,-1];  

        push @minima, $local_minimum; 
        push @maxima, $local_maximum;  
    }

    return ( \@minima, \@maxima ); 
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
    my ( $output, $md, $period, ) = @_; 

    # extract array of potentials (last column)
    my @potentials = map { $md->{$_}[-1] } sort{ $a <=> $b } keys %$md; 
    
    # total number of averages point
    my $naverage = scalar(@potentials) - $period + 1; 

    # calculating moving average 
    print "=> $output: Short-time averages of potential energy over period of $period steps\n"; 

    my $index = 0; 
    my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  
    for ( 1..$naverage ) { 
        my $average = (sum(@potentials[$index..($index+$period-1)]))/$period; 
        printf $fh "%d\t%10.5f\n", ++$index, $average; 
    }
    $fh->close; 

    return; 
}

#--------# 
# DOSCAR #
#--------# 

# read DOSCAR
# args 
# -< DOSCAR file (default)
# return 
# -> dos array 
sub read_doscar { 
    my $file = shift @_ || 'DOSCAR';  

    # 6th line: DOS header  
    # 7th line: Total DOS (3 or 5 columns)
    my $doscar_6th = extract_file($file, 6); 
    my $doscar_7th = extract_file($file, 7); 
    
    # min, max, nedos, fermi, spin ? 
    my ( $max, $min, $nedos, $fermi, $colinear ) = split ' ', $doscar_6th; 
    
    # ISPIN = 1: 3 columns 
    # ISPIN = 2: 5 columns 
    printf "NEDOS   = %d\n", $nedos; 
    printf "E_min   = %.3f eV\n", $min; 
    printf "E_max   = %.3f eV\n", $max; 
    printf "E_fermi = %.3f eV\n", $fermi; 
    printf "ISPIN   = %d\n", (scalar(split ' ', $doscar_7th)) == 3 ? 1 : 2; 
   
    # dos array 
    # ldos[0]: total DOS  
    # ldos[n]: nth ion DOS 
    my ( $header, @dos ) = split /$doscar_6th\n/, slurp_file($file); 

    return @dos; 
}

# print DOS 
# args 
# -< filename
# -< slurped dos
# return 
# -> null
sub print_dos { 
    my ( $file, $dos ) = @_; 

    my $fh = IO::File->new($file, 'w'); 

    printf $fh $dos;  

    $fh->close(); 

    return; 
}

# sum LDOS  
# args 
# -< filehandler
# -< LDOS files 
# return 
# -> null 
sub sum_dos { 
    my ( $sum_file, @files ) = @_; 

    # format depends on number of column in LDOS-*
    my $format = 
    ( split ' ', extract_file($files[0],1) ) == 10 ?  
    fortran2perl('%11.3f,9%12.4E') : 
    fortran2perl('%11.3f,18%12.4E'); 

    # hash of array ref ( energy => [s p d] )
    my %sum_dos; 
    for my $ldos ( @files ) { 
        my $slurped_dos = slurp_file($ldos); 
        my $dos_fh = IO::File->new(\$slurped_dos, 'r'); 

        while ( <$dos_fh> ) { 
            my ( $energy, @dos ) = split;    
            for ( 0..$#dos ) {  
                $sum_dos{$energy}[$_] += $dos[$_]; 
            }
        }
    }

    my $fh = IO::File->new($sum_file, 'w'); 
    # print DOS summation
    for ( sort { $a <=> $b } keys %sum_dos ) { 
        printf $fh "$format\n", $_, @{$sum_dos{$_}}; 
    }
    $fh->close; 

    return; 
}

#----------# 
# EIGENVAL #
#----------# 

# extract eigenvalue for band plot 
# args
# -< EIGENVAL file (default)
# return 
# -> hash ref { band# => [ eigenvalue ] }
sub read_band { 
    my $file = shift @_ || 'EIGENVAL';  
    
    # header and band block are separated by a blank line
    my ( $header, @bands ) = split /\n+\s*\n+/, slurp_file($file); 
    
    # last line of the header 
    my ( $nelectron, $nkpoint, $nband ) = split ' ', ( split /\n/, $header )[-1]; 
   
    my %eigen; 
    my $count = 0; 
    for my $band ( @bands ) { 
        $count++; 
        push @{$eigen{$count}}, map { ( split )[-1] } split /\n/, $band; 
        # remove header of band block
        shift @{$eigen{$count}}; 
    }

    return %eigen; 
}

#---------# 
# KPOINTS #
#---------# 

# parse KPOINTS file 
# args 
# -< none (default: 'KPOINTS') 
# return 
# -> mode (Cart/Direct/Line-mode)
# -> ref to array of kpoint
sub read_kpoints { 
    my $file = shift @_ || 'KPOINTS';  
    
    # parse KPOINTS 
    chomp ( my ( $comment, $nkpoint, $mode, @kblock ) = read_file($file) ); 

    # automatic k-mesh generation
    my @kpoints = (); 
    if ( $nkpoint == 0 ) { 
        @kpoints = split ' ', shift @kblock;  
    } else { 
        # 4th column is kpoint weight
        @kpoints = map { [(split)[0,1,2]] } @kblock; 
    }

    return ( $nkpoint, $mode, @kpoints ); 
}

#--------#
# POSCAR #
#--------#

# args 
# -< POSCAR/CONTCAR/XDATCAR (default: POSCAR)
# return 
# -> structure name 
# -> scaling 
# -> ref to 2d array of lattice vectors
# -> ref to array of atom
# -> ref to array of number of atom
# -> selective dynamic (0 or 1)
# -> type of coordinate (direct/cartesian)
sub read_poscar { 
    my $file = shift @_ || 'POSCAR';  

    my @lines = read_file($file); 

    my ($title, $scaling, $lat, $atom, $natom, $dynamics, $type, $geometry);  
    # header block 
    $title   = shift @lines; 
	# scaling constant
	$scaling = shift @lines; 
    # lattice vectors with scaling contants
    $lat     = [ map { [split ' ', shift @lines] } 1..3 ]; 
    # scaled lattice vector
    $lat     = mat_mul($scaling, $lat);  
    # array of element 
	$atom    = [ split ' ', shift @lines ]; 
    # array of number of atoms per element
	$natom   = [ split ' ', shift @lines ]; 
    # selective dynamics ? 
    $dynamics = shift @lines; 
    # direct or cartesian coordinate 
    #my $type     = ($dynamics =~ /selective/i) ? shift @$line : $dynamics; 
    if ( $dynamics =~ /^\s*s/i ) { 
        $type = shift @lines
    } else { 
        $type     = $dynamics; 
        $dynamics = 0; 
    }
    # backward compatability for XDATCAR produced by vasp 5.2.x 
    #if ($type =~ //) { $type = 'direct' }; 

    # geometry block  
    while ( my $atom = shift @lines ) { 
        last if $atom =~ /^\s+$/; 
        push @$geometry, [split ' ', $atom]; 
    }

    return ($title, $scaling, $lat, $atom, $natom, $dynamics, $type, $geometry); 
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
# -< POTCAR
# return 
# -> 2d array of pp => [ type, element, config ];  
sub read_potcar { 
    my $file = shift @_ || 'POTCAR';  

    my ( @pp, $shell_config );  
    for( read_file($file) ) { 
        if ( /VRHFIN/ ) { 
            $shell_config = ( split /:/ )[-1]; 

        }
        if ( /TITEL/ ) { 
            my ( $type, $element ) = ( split )[2,3]; 
            push @pp, [$type, $element, $shell_config]; 
        }
    }

    return @pp;  
} 

# print elements in POTCAR 
# args 
# -> 2d array of pp => [ type, element, config, date ];  
# return 
# -> null 
sub print_potcar { 
    my @pp = @_; 

    # string format
    my $elem_length  = length(map $_->[1], @pp);  
    my $shell_length = length(map $_->[2], @pp);  

    print "=> Pseudopotential:\n";  

    for my $pp ( @pp ) { 
        printf "=|%-s|=   %-${elem_length}s %-${shell_length}s\n", @$pp;  
    }

    return; 
}

# POTCAR creation
# args 
# -< POTCAR  
# -< directory of pseudopotentials 
# -< type of potential 
# -< element in periodic table 
# return 
# -> null 
sub make_potcar { 
    my ( $file, $dir, $potential, @element ) = @_; 

    my $fh = IO::File->new($file, 'w') or die "Cannot write to $file\n";  

    for my $element ( @element ) { 
        # list the available potentials 
        my @avail_pots = map { basename $_ } grep /\/($element)(\z|\d|_|\.)/, <$dir/$potential/*>;
        printf "=> Pseudopotentials for %s: =| %s |=\n", element_name($element), join(' | ', @avail_pots); 

        # Promp user to choose potential 
        while ( 1 ) { 
            print "=> Choice: "; 
            # remove newline, spaces, etc
            chomp ( my $choice = <STDIN> ); 
            $choice =~ s/\s+//g; 

            # fullpath for chosen potential 
            if ( grep { $choice eq $_ } @avail_pots ) { 
                my $potcar = slurp_file(catfile($dir, $potential, $choice, 'POTCAR')); 
                print $fh $potcar; 
                # extra blank line
                if ( $element ne $element[-1] ) { print "\n" }  
                last; 
            }
        }
    }
    $fh->close( ); 

    return; 
}

#---------#
# OSZICAR #
#---------#

#read istep, T(K), F(eV) from OSZICAR 
# args  
# -< ref to array of lines 
# return 
# -> potential hash (istep => [T, F])
sub read_profile { 
    my $file = shift @_ || 'OSZICAR';  

    my @md = map [(split)[0,2,6]], grep /T=/, read_file($file); 

    # convert array to hash for easier index tracking 
    my %md = map { $_->[0] => [$_->[1], $_->[2] ] } @md; 
    
    # total number of entry in hash
    print  "=> Retrieve ISTEP, T(K), and F(eV) from OSZICAR\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %md); 
    
    return %md; 
}

# print potential profile to file 
# args  
# -< ref to potential hash (istep => [T,F])
# -< output file 
# return 
# -> null
sub print_profile { 
    my ( $output, $md ) = @_; 

    my $fh = IO::File->new($output, 'w') or die "Cannot write to $output\n";  
    print $fh "# Step  T(K)   F(eV)\n"; 
    map { printf $fh "%d  %.1f  %10.5f\n", $_, @{$md->{$_}} } sort {$a <=> $b} keys %$md;  
    $fh->close; 

    return; 
}

#--------#
# OUTCAR #
#--------#

# read total forces of each ion step 
# args 
# -< OUTCAR 
# return 
# -> hash of max forces  
sub read_force { 
    my $file = shift @_ || 'OUTCAR';   
    
    my ($nion, @max_forces); 
    my $slurp_line = slurp_file($file); ; 
    
    # number of ion (NIONS)
    if ( $slurp_line =~ /NIONS.+?(\d+)/ ) { $nion = $1 } 

    # filehandler to scalar ref
    my $fh = IO::File->new(\$slurp_line, 'r'); 
    
    # force header: TOTAL-FORCE
    while (<$fh>) { 
        if (/TOTAL-FORCE/) { 
            my @forces = ();  
            # skip '---' 
            my $line = <$fh>;  
            # move record NIONS ahead 
            for (1..$nion) { 
                $line = <$fh>; 
                my @fxyz =  (split ' ', $line)[3,4,5]; 
                push @forces, sqrt($fxyz[0]**2+$fxyz[1]**2+$fxyz[2]**2);
            }
            # max forces 
            push @max_forces, max(@forces);  
        }
    }
    $fh->close; 
    
    return @max_forces;  
}

# read the eigenvectors and eigenvalues of dynamical matrix 
# args
# -< ref to array of OUTCAR lines 
# return 
# -> ref to hash: 
# 1 => { [ frequency, 
#          [dx dy dz] 
#          ....
#        ]
#      }, 
# 2 => ...
sub read_phonon_eigen { 
    my $file = shift @_ || 'OUTCAR';   

    my ( $nion, $ndof, %eigen ); 
    my $slurp_line = slurp_file($file);  
    
    # number of ion (NIONS)
    if ( $slurp_line =~ /NIONS.+?(\d+)/ ) { $nion = $1 } 

    # number of degree of freedom (DOF)
    if ( $slurp_line =~ /DOF.+?(\d+)/ ) { $ndof = $1 } 

    # filehandler to scalar ref
    my $fh = IO::File->new(\$slurp_line, 'r'); 
    
    while ( <$fh> ) { 
        if ( /Eigenvectors and eigenvalues/ ) { 
            my $line; 
            # skip three lines 
            for ( 1..3 ) { $line = <$fh> } 

            for my $dof ( 1..$ndof ) { 
                # eigenvalue 
                if ( ( $line = <$fh> ) =~ /\d+\s+f/ ) { $eigen{$dof}[0] = ( split ' ', $line )[-2] } 

                # skip 'X  Y  Z' header
                $line = <$fh>; 

                # move record NIONS ahead 
                for ( 1..$nion ) { 
                    $line = <$fh>; 
                    push @{$eigen{$dof}}, [( split ' ', $line )[-3,-2,-1]]; 
                }
                
                # skip blank line
                $line = <$fh>;     
            }
        }
    }
    
    return %eigen; 
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
    my ($file) = @_; 

    my $line = defined $file ? slurp_file($file) : slurp_file('XDATCAR');  
    
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
sub retrieve_taj { 
    my ($stored_traj) = @_; 

    # trajectory is required 
    die "$stored_traj does not exists\n" unless -e $stored_traj; 
    # retored traj as hash reference 
    my $traj = retrieve($stored_traj); 
    print  "=> Retrieve trajectory from '$stored_traj'\n"; 
    printf "=> Hash contains %d entries\n\n", scalar(keys %$traj); 

    return %$traj; 
}

# last evaluated expression 
1;
