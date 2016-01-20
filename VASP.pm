package VASP; 

use strict; 
use warnings; 

use Data::Dumper; 
use Exporter; 
use File::Basename; 
use File::Spec::Functions; 
use Storable qw( store retrieve );  

use Fortran qw( fortran2perl ); 
use Math::Linalg qw( max sum product length print_array mscale print_mat ); 
use Periodic qw( element_name atomic_symbol );  
use Util qw( read_file slurp_file paragraph_file extract_file );  

our @doscar   = qw( read_doscar print_ldos sum_ldos_files sum_ldos_cols ); 
our @eigenval = qw( read_band ); 
our @incar    = qw( read_init_magmom ); 
our @kpoints  = qw( read_kpoints );  
our @poscar   = qw( read_poscar print_poscar ); 
our @potcar   = qw( read_potcar print_potcar make_potcar ); 
our @oszicar  = qw( read_md print_md ); 
our @outcar   = qw( read_cell read_final_magmom read_force read_phonon ); 
our @xdatcar  = qw( read_xdatcar ); 
our @vasp     = qw( run_vasp ); 

our @ISA         = qw( Exporter );  
our @EXPORT      = ();  
our @EXPORT_OK   = ( @doscar, @eigenval, @incar, @kpoints, @poscar, @potcar, @oszicar, @outcar, @xdatcar, @vasp ); 
our %EXPORT_TAGS = ( 
    doscar   => \@doscar, 
    eigenval => \@eigenval, 
    incar    => \@incar, 
    kpoints  => \@kpoints, 
    poscar   => \@poscar, 
    potcar   => \@potcar, 
    oszicar  => \@oszicar,
    outcar   => \@outcar, 
    xdatcar  => \@xdatcar, 
    vasp     => \@vasp, 
); 

#--------# 
# DOSCAR #
#--------# 

# read DOSCAR
# args 
# -< DOSCAR 
# return 
# -> hash of doscar
sub read_doscar { 
    my ( $file ) = @_;  

    my %dos = (); 

    # 1th line: header 
    # 6th line: DOS info
    # 7th line: Total DOS (3 or 5 columns)
    my ( $header, $info, $dos_line ) = extract_file($file, 1, 6, 7); 

    # nion 
    @dos{qw(nion)} = (split ' ', $header)[0]; 

    # min, max, nedos, fermi, spin ? 
    @dos{qw( max min nedos fermi )} = split ' ', $info; 

    # ISPIN = 1: 3 columns 
    # ISPIN = 2: 5 columns 
    my @columns = split ' ', $dos_line; 
    $dos{ispin} = ( @columns == 3 ? 1 : 2 ); 
    
    # DOS info 
    printf "NION    = %d\n", $dos{nion}; 
    printf "NEDOS   = %d\n", $dos{nedos}; 
    printf "E_min   = %.3f eV\n", $dos{min}; 
    printf "E_max   = %.3f eV\n", $dos{max}; 
    printf "E_fermi = %.3f eV\n", $dos{fermi}; 
    printf "ISPIN   = %d\n", $dos{ispin}; 

    # dos blocks
    my @proj_dos = (); 
    ( undef, @proj_dos ) = split /$info\n/, slurp_file($file); 
    
    # indexing 
    # 0: total DOS  
    # n: nth ion DOS 
    @dos{0..scalar(@proj_dos)} = @proj_dos; 

    return %dos; 
}

# print DOS 
# args 
# -< slurped dos
# -< filename
# return 
# -> null
sub print_ldos { 
    my ( $dos => $output ) = @_; 

    open my $fh, '>', $output or die "Cannot write to $output\n"; 
    printf $fh $dos;  
    close $fh; 

    return;
}

# sum LDOS  
# args 
# -< ref of array of LDOS files  
# -< sum LDOS file 
# return 
# -> null 
sub sum_ldos_files { 
    my ( $dos => $sum_dos ) = @_; 

    # probe LDOS for number of column 
    my $dos_line = extract_file($dos->[0], 0);  
    my @ncolumn = split ' ', $dos_line; 
    my $dos_nc  = scalar(@ncolumn)-1; 

    # output format  
    my $format  = fortran2perl("%11.3f,${dos_nc}%12.4E"); 

    # hash of array ref ( energy => [s p d f] )
    my %sum_dos = ();  
    for my $ldos ( @$dos ) { 
        # slurp the LDOS file 
        my $slurped_dos = slurp_file($ldos); 
       
        # scalar ref to slurped ldos 
        open my $dos_fh, '<', \$slurped_dos; 

        while ( <$dos_fh> ) { 
            my ( $energy, @dos ) = split;    
            # accumulate LDOS 
            for ( 0..$#dos ) {  
                $sum_dos{$energy}[$_] += $dos[$_]; 
            }
        }

        close $dos_fh;  
    }

    # print %sum_dos to $sum_dos
    open my $fh, '>', $sum_dos or die "Cannot write to $sum_dos\n"; 

    for ( sort { $a <=> $b } keys %sum_dos ) { 
        printf $fh "$format\n", $_, @{$sum_dos{$_}};  
    }

    close $fh; 
    
    return; 
}

# sum LDOS column 
# args 
# -< LDOS file 
# -< ref of array of orbital 
# -< column-wised sum LDOS file
sub sum_ldos_cols { 
    my ( $file, $orbital => $sum_dos ) = @_; 

    # default
    my $ispin = 1; 

    # LDOS column information 
    # 1: non-spin polarized 
    # 2: spin  polarized 
    my %column = ( 
        '1' => { 's' => [1],   'p' => [2..4], 'd' => [5..9],  'f' => [10..16] }, 
        '2' => { 's' => [1,2], 'p' => [3..8], 'd' => [9..18], 'f' => [19..32] }, 
    ); 
   
    # probe file for ispin 
    my $dos_line  = extract_file($file, 1); 
    my @columns = split ' ', $dos_line; 
    if ( @columns == 19 || @columns == 33 ) { $ispin = 2 } 

    # slurp the LDOS file 
    # scalar ref to slurped ldos 
    my $slurped_dos = slurp_file($file); 
    open my $dos_fh, '<', \$slurped_dos; 
    
    my %ldos_sum = (); 
    while ( <$dos_fh> ) { 
        my @csplit = split; 
        # energy: 1st col 
        my $energy = $csplit[0]; 

        # loop through set of l QM ( too ugly )
        for my $l ( @$orbital ) {  
            # projected f is not always exists 
            my @ldos = grep defined, @csplit[@{$column{$ispin}{$l}}]; 

            # 1: non-spin 
            if ( $ispin == 1 ) { 
                push @{$ldos_sum{$energy}}, ( @ldos == 0 ? 0 : sum(@ldos) ); 
            # 2: spin-polarized 
            } else { 
                if ( @ldos == 0 ) { 
                    push @{$ldos_sum{$energy}}, 0, 0; 
                } else { 
                    # too ugly 
                    my @up   = grep { ($_ % 2) == 0 } 0..$#{$column{$ispin}{$l}}; 
                    my @down = grep { ($_ % 2) == 1 } 0..$#{$column{$ispin}{$l}}; 
                    push @{$ldos_sum{$energy}}, sum(@ldos[@up]), sum(@ldos[@down]); 
                }
            }
        } 
    }

    close $dos_fh; 
    
    # format 
    my $format = 
    $ispin == 1 ?  
    fortran2perl('%11.3f,'.scalar(@$orbital).'%12.4E'):  
    fortran2perl('%11.3f,'.(2*scalar(@$orbital)).'%12.4E'); 

    # filehandler to output 
    open my $sum_fh, '>', $sum_dos or die "Cannot write to $sum_dos\n"; 

    for my $energy ( sort { $a <=> $b } keys %ldos_sum ) { 
        printf $sum_fh "$format\n", $energy, @{$ldos_sum{$energy}}; 
    }

    close $sum_dos; 
}

#----------# 
# EIGENVAL #
#----------# 

# extract eigenvalue for band plot 
# args
# -< EIGENVAL
# -< ref of band hash { band# => [ eigenvalue ] }
# return 
sub read_band { 
    my ( $file ) = @_;  

    my %eigenval = (); 

    # header and band block are separated by a blank line
    my ( $header, @bands ) = split /\n+\s*\n+/, slurp_file($file); 

    # eigenval information  
    my ( $nelectron, $nkpoint, $nband ) = split ' ', ( split /\n/, $header )[-1]; 

    # band info 
    printf "NELEC   = %d\n", $nelectron;  
    printf "NKPOINT = %d\n", $nkpoint;  
    printf "NBAND   = %d\n", $nband;  

    my $count = 0; 
    for my $band ( @bands ) { 
        $count++; 
        push @{$eigenval{$count}}, map { ( split )[-1] } split /\n/, $band; 
        # remove header of band block
        shift @{$eigenval{$count}}; 
    }

    return %eigenval;  
}

#-------# 
# INCAR #
#-------# 

# read initial magmom  
# args 
# -< INCAR 
# return 
# -< array of magmom 
sub read_init_magmom { 
    my ( $file ) = @_;  

    my @init_magmom = (); 

    for ( read_file($file) ) { 
        if ( /^.*#/ ) { next } 
        if ( /MAGMOM/ ) { 
            my ( undef, $magmom ) = split /=/; 
            for ( split ' ', $magmom ) { 
                push @init_magmom, ( /(\d+)\*(.*)/ ? ($2)x$1 : $_ );  
            }
        }
    }

    return @init_magmom;  
}

#---------# 
# KPOINTS #
#---------# 

# parse KPOINTS file 
# args 
# -< KPOINTS 
# -< ref of number of kpoint 
# -< ref of mode 
# -< ref of k mesh 
# return 
# -> null
sub read_kpoints { 
    my ( $file ) = @_;  

    my ( %kpoint, @kblock ) = (); 

    # parse KPOINTS 
    my @lines = read_file($file);  
    chomp (( undef, $kpoint{nkpt}, $kpoint{mode}, @kblock ) = @lines ); 

    # automatic k-mesh generation
    if ( $kpoint{nkpt} == 0 ) { 
        $kpoint{mesh} = [ split ' ', shift @kblock ];  
    } else { 
        # 4th column is kpoint weight
        $kpoint{mesh} = [ map [ ( split )[0,1,2] ],  @kblock ];  
    }

    return %kpoint;  
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
    my ( $file ) = @_;  

    # poscar hash  
    my %poscar = (); 
    
    # read_poscar; 
    my @lines = read_file($file); 

    # header/name/commnet 
    $poscar{name}  = shift @lines; 

    # scaling 
    $poscar{scaling} = shift @lines; 

    # lattice vectors ( 2d array ref ) 
    map { $poscar{cell}[$_] = [split ' ', shift @lines] } 0..2;   

    # version checking: 6th line
    my $version_probe = shift @lines;  
    if ( element_name(split ' ', $version_probe) ) {  
        # VASP 5 :)
        $poscar{version} = 5; 
        $poscar{atom}    = [ split ' ', $version_probe ]; 
        $poscar{natom}   = [ split ' ', shift @lines ]; 
    } else { 
        # VASP 4 :(
        $poscar{version} = 4; 
        # extract elements from POSCAR ... 
        my %pp = read_potcar('POTCAR'); 
        $poscar{atom}  = [ list_potcar_element(\%pp) ];  
        # one line offset  
        $poscar{natom} = [ split ' ', $version_probe ]; 
    }

    # selective dynamics 
    my $selective_probe = shift @lines; 
    if ( $selective_probe =~ /^\s*S/i ) { 
        $poscar{selective} = 1; 
        $poscar{type} = shift @lines; 
    } else { 
        $poscar{selective} = 0;  
        # one line offset  
        $poscar{type} = $selective_probe; 
    } 

    #-----------------# 
    # post processing #
    #-----------------# 
    # VASP4 sanity check
    if ( @{$poscar{atom}} < @{$poscar{natom}} ) { die "VASP4: Mismatch between $file and POTCAR\n" }

    # in case @atom > @natom, trim down the array 
    @{$poscar{atom}} = splice @{$poscar{atom}}, 0, scalar(@{$poscar{natom}}); 

    # apply scaling to lattice vectors 
    @{$poscar{cell}} = mscale($poscar{scaling}, $poscar{cell}); 

    # convert geometry block to 2d array 
    $poscar{geometry} = [ map [ (split) ], ( splice @lines, 0, sum(@{$poscar{natom}}) ) ]; 

    # frozen atom: traverse the geometry array again
    $poscar{frozen} = []; 
    for ( @{$poscar{geometry}} ) { 
        my @frozen = splice @$_, 3, 3;  
        # genuine selective tags 
        if ( grep /T|F/, @frozen ) { 
            push @{$poscar{frozen}}, \@frozen; 
        # fallback: default T T T
        } else { 
            push @{$poscar{frozen}}, [ qw( T T T) ]; 
        }
    }

    # if cartesian is used, apply scaling constant
    # cant use mscale here because of 'dynamic tag'
    if ( $poscar{type} =~ /^\s*c/i ) { map { map { $_ *= $poscar{scaling} } @$_[0..2] } @{$poscar{geometry}} };  

    return %poscar;  
}

# args  
# -< hash ref of poscar 
# -< POSCAR file 
# return
# -> null
sub print_poscar { 
    my ( $poscar => $output ) = @_; 

    # format
    my $format_1 = scalar(@{$poscar->{atom}}).'%5s';  
    my $format_2 = scalar(@{$poscar->{natom}}).'%6d'; 

    # coordinate 
    my $format_3 = $poscar->{selective} ? '3%22.16f3%5s%6d' : '3%22.16f%6d';   

    # write to POSCAR 
    open my $fh, '>', $output or die "Cannot write to $output\n"; 

    # name 
    printf $fh "%s\n", $poscar->{name}; 

    # scaling 
    printf $fh "%d\n", $poscar->{scaling}; 

    # lattice vector 
    print_mat($fh, '3%22.16f', $poscar->{cell});  

    # VASP 5 format
    if ( $poscar->{version} == 5 ) { print_array($fh, $format_1, $poscar->{atom}) }; 

    # number of atom 
    print_array($fh, $format_2, $poscar->{natom}); 

    # selective dynamics 
    if ( $poscar->{selective} ) { printf $fh "%s\n", 'Selective dynamics' }  

    # direct || cartesian 
    printf $fh "%s\n" , $poscar->{type}; 

    # geometry block
    my $natom = sum(@{$poscar->{natom}}); 

    if ( $poscar->{selective} ) { 
        map { splice @{$poscar->{geometry}[$_]}, 3, 4, @{$poscar->{frozen}[$_]}, $_+1 } 0..$natom-1; 
    } else { 
        map { splice @{$poscar->{geometry}[$_]}, 3, 4, $_+1 } 0..$natom-1; 
    }

    # print_coordinate 
    print_mat($fh, $format_3, $poscar->{geometry}); 

    close $fh;  

    return; 
}

#--------#
# POTCAR #
#--------#

# read list of PP in POTCAR 
# args  
# -< POTCAR
# return 
# -> hash of pseudopotention: PAW_PBE => [ Iron, Fe_pv, d7s1, 14Sep2000 ]
sub read_potcar { 
    my ( $file ) = @_;  

    my %pp = ();  
    my ( $pseudo, $element, $config, $shell, $date );  

    for ( read_file($file) ) { 
        if ( /VRHFIN =(\w+)\s*:(.*)/ ) { 
            $element = element_name($1);  
            # valence shell 
            if ( my @valence = ( $2 =~ /([spdf]\d+)/g ) ) {  
                $shell = join '', @valence;               
            } else { 
                $shell = (split ' ', $2)[0];  
            }
        }

        if ( /TITEL/ ) { 
            ( $pseudo, $config, $date ) = ( split )[2,3,4]; 
            $date = $date ? $date : '...'; 
            push @{$pp{$pseudo}},[ $element, $config, $shell, $date ]; 
        }
    }

    return %pp;   
} 

# read list of element in POTCAR 
# args 
# -< hash ref of pseudopotential 
# return 
# -> array of element 
sub list_potcar_element { 
    my ( $pp ) = @_; 

    # flatten the hash: 
    my @pp = map @{$pp->{$_}}, sort keys %$pp; 

    # atomic symbol 
    my @symbols = map atomic_symbol($_), map $_->[0], @pp;  

    return @symbols; 
}

# print elements in POTCAR 
# args 
# -< hash ref of pseudo potention: PAW_PBE => [ Iron, Fe_pv, d7s1, 14Sep2000 ]
# return 
# -> null 
sub print_potcar { 
    my ( $pp ) = @_; 

    # empty array of pseudopotential 
    if ( keys %$pp == 0 ) { return 0 }

    # flatten the hash: 
    my @pp = map @{$pp->{$_}}, sort keys %$pp; 

    # format 
    my @formats = (); 
    for my $index (0..3) { 
        push @formats, length(map $_->[$index], @pp);  
    }

    for ( sort keys %$pp ) {  
        printf  "Pseudopotential: <%s>\n", $_; 
        for ( @{$pp->{$_}} ) { 
            printf "-> %-$formats[0]s\t%-$formats[1]s\t%$formats[2]s\t%$formats[3]s\n", @$_; 
        }
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
    my ( $dir, $potential, $elements => $output ) = @_; 

    # empty array of elements 
    if ( @$elements == 0 ) { return 0 } 

    open my $fh, '>', $output or die "Cannot write to $output\n"; 


    for my $element ( @$elements ) { 
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
                if ( $element ne $elements->[-1] ) { print "\n" }  
                last; 
            }
        }
    }

    close $fh; 

    return; 
}

#---------#
# OSZICAR #
#---------#

#read istep, T(K), F(eV) from OSZICAR 
# args  
# -< OSZICAR 
# return 
# -> hash md profile (istep => [T, F])
sub read_md { 
    my ( $file ) = @_;  

    # [istep, T, F]
    my @md = map [ ( split )[0,2,6] ], grep /T=/, read_file($file); 

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
sub print_md { 
    my ( $md => $output ) = @_; 

    open my $fh, '>', $output or die "Cannot write to $output\n"; 

    print $fh "# Step  T(K)   F(eV)\n"; 
    map { printf $fh "%d  %.1f  %10.5f\n", $_, @{$md->{$_}} } sort {$a <=> $b} keys %$md;  

    close $fh;  

    return; 
}

#--------#
# OUTCAR #
#--------#
# read lattice vectors (ISIF 3) 
# args 
# -< OUTCAR 
# return 
# -> array of optimized lattice vectors 
sub read_cell { 
    my ( $file ) = @_;  

    my $slurp_line = slurp_file($file); 

    # filehandler to scalar ref
    my @lattices = ( ); 
    open my $fh, '<', \$slurp_line; 
    while ( <$fh> ) { 
        if ( /direct lattice vectors/ ) { 
            my @lattice = ( );  
            for ( 1..3 ) { 
                my $lat_line = <$fh>;  
                push @lattice, [ (split ' ',$lat_line)[0..2] ]; 
            }
            push @lattices, \@lattice; 
        }
    } 
    close $fh;  

    # the 1st lattice is from POSCAR! 
    shift @lattices; 

    return @lattices; 
}

# read final magmom 
# args 
# -< OUTCAR 
# return 
# -> array of final magmom 
sub read_final_magmom { 
    my ( $file ) = @_;  

    my ( $nion, @magmom );  
    my $slurp_line = slurp_file($file); 

    # spin polarization or not ?  
    if ( ! $slurp_line =~ /ISPIN\s*=\s*2/ ) { return } 

    # number of ion (NIONS)
    if ( $slurp_line =~ /NIONS.+?(\d+)/ ) { $nion = $1 } 

    # filehandler to scalar ref 
    open my $fh, '<', \$slurp_line; 
    while ( <$fh> ) { 
        if ( /magnetization \(x\)/ ) { 
            my ( $line, @imag ); 
            # skip 3 lines 
            for (1..3) { $line = <$fh> }
            for my $ion ( 0..$nion-1 ) { 
                my $line = <$fh>; 
                push @imag, ( split ' ', $line )[-1]; 
            }
            push @magmom, \@imag;  
        }
    }
    close $fh; 

    return @{$magmom[-1]};  
}

# read total forces of each ion step 
# args 
# -< OUTCAR 
# return 
# -> array of forces  
sub read_force { 
    my ( $file, $frozen ) = @_;  

    my ( $nion, @max_forces ); 
    my $slurp_line = slurp_file($file); 

    # number of ion (NIONS)
    if ( $slurp_line =~ /NIONS.+?(\d+)/ ) { $nion = $1 } 

    # filehandler to scalar ref
    open my $fh, '<', \$slurp_line; 
    while ( <$fh> ) { 
        if ( /TOTAL-FORCE/ ) { 
            my @forces = ();  
            # skip '---' 
            my $line = <$fh>;  
            # move record NIONS ahead 
            for my $ion ( 0..$nion-1 ) { 
                $line = <$fh>; 
                my @fxyz =  (split ' ', $line)[3,4,5]; 
                # skip frozen atoms 
                if ( grep $ion eq $_, @$frozen ) { next }
                # array of forces 
                push @forces, sqrt($fxyz[0]**2+$fxyz[1]**2+$fxyz[2]**2);
            }
            # max forces 
            push @max_forces, max(@forces);  
        }
    }
    close $fh;  

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
sub read_phonon { 
    my ( $file ) = @_;  

    my ( $nion, %eigen ); 
    my $slurp_line = slurp_file($file);  

    # number of ion (NIONS)
    if ( $slurp_line =~ /NIONS.+?(\d+)/ ) { $nion = $1 } 

    # filehandler to scalar ref
    open my $fh, '<', \$slurp_line; 

    while ( <$fh> ) { 
        if ( /\d+\s+f(\/i)?\s+=/ ) { 
            # read eigenval 
            my ( $dof, $eigenval ) = ( split )[0, -2]; 
            $eigen{$dof}[0] = $eigenval; 

            # skip the X Y Z dx dy dz header 
            my $line = <$fh>;     

            # read eigenvector 
            for ( 1..$nion ) { 
                $line = <$fh>;
                push @{$eigen{$dof}}, [( split ' ', $line )[-3,-2,-1]]; 
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
# -< XDATCAR
# return
# -> XDATCAR hash 
sub read_xdatcar { 
    my ( $file ) = @_;  

    my %xdatcar = (); 

    # probe version
    if ( extract_file('XDATCAR', 4) =~ /CAR/ ) { 
        # VASP 4 :( 
        
        # read name, scaling, atom, natom from POSCAR 
        %xdatcar = read_poscar('POSCAR');  
        
        # read cell info from the OUTCAR 
        my @icell = read_cell('OUTCAR'); 

        # keep trajs as scalars  
        # avoid exciplit read in the file 
        my $seperator = extract_file($file, 6);  
        my ( undef, undef, undef, @geometry ) = split /$seperator\n| Konfig=.+?\n/, slurp_file('XDATCAR'); 
        
        # modify hash accordingly 
        @xdatcar{qw(version cell type selective geometry)} = ( 4, \@icell, 'direct', 0, \@geometry ); 
    } else { 
        # VASP 5 :)

        my $name = extract_file($file, 1); 
        my ( undef, @block ) = split /$name\n|Direct configuration=.*\d+\n/, slurp_file('XDATCAR');

        # precompiled regular expression 
        my $regex_scaling = qr/^\s*\d*(\.)?\d+\s*\n/;   
        my $regex_xyz     = qr/^\s*(-?\d*(\.?)\d+\s*){3}\n/; 

        my @icell     = grep /$regex_scaling/, @block; 
        my @igeometry = grep /$regex_xyz/, @block; 

        # ISIF =3 
        if ( @icell > @igeometry ) { shift @icell };  

        # what an ugly code  
        $xdatcar{atom}  = [ $icell[0] =~ /([A-Za-z]+)+/g ];  
        $xdatcar{natom} = [ ( $icell[0] =~ /(\d+)+/g )[-@{$xdatcar{atom}}..-1 ] ]; 

        # cell block 
        for my $cell ( @icell ) { 
            my @clines = split /\n/, $cell; 

            my $scaling = shift @clines; 
            my @cell =  map { [ split ' ', shift @clines ] } 0..2;  

            # scaling lattice vector 
            @cell = mscale($scaling, \@cell);  

            push @{$xdatcar{cell}}, \@cell; 
        }

        # geometry block  
        $xdatcar{geometry} = [ map { [ map [split], split /\n/ ] } @igeometry ];  
    }
    
    return %xdatcar; 
}

#------# 
# VASP #
#------# 
# execute vasp 
# args 
# -< working path 
# -< hash ref of vasp binary => version => {gamma, complex} 
# -< version 
# -< sratch directory ( for iterative mode ) 
# return 
# -> null 
sub run_vasp { 
    my ( $path, $binary, $version, $scratch ) = @_; 
    
    my $vasp   = '';  
    my $nprocs = `wc -l < $ENV{PBS_NODEFILE}`; 
    my @inputs = qw( INCAR KPOINTS POSCAR POTCAR ); 

    # relocate to calculation directory 
    chdir $path;

    # iterative mode 
    if ( defined $scratch && $path ne $scratch && -e 'OUTCAR' ) { return } 
    
    # INCAR, KPOINTS, POSCAR, POTCAR
    if ( ( grep -e $_, @inputs ) == 4 ) { 
        my %kpoint = read_kpoints('KPOINTS'); 

        # explicit kpoint 
        if ( $kpoint{nkpt} > 0 ) {  
            $vasp = $binary->{$version}{'complex'};  
        # automatic kpoint mesh 
        } else { 
            $vasp = int(product(@{$kpoint{mesh}})) == 1 ? $binary->{$version}{'gamma'} : $binary->{$version}{'complex'};  
        }
        
        system 'mpirun', '-np', $nprocs, $vasp; 
    }
    
    return; 
}

# last evaluated expression 
1;
